$ErrorActionPreference = "SilentlyContinue"
Clear-Host

$baseDir = $PSScriptRoot
$binDir = Join-Path $baseDir "bin"
$libraryDir = Join-Path $baseDir "library"
$ytDlp = Join-Path $binDir "yt-dlp.exe"
$ffmpeg = Join-Path $binDir "ffmpeg.exe"
$sessionStamp = Get-Date -Format "yyyy-MM"

function Show-Status {
    param(
        [string]$Message,
        [string]$Type = "info"
    )

    $prefix = switch ($Type) {
        "info" { "[INFO]" }
        "success" { "[OK]" }
        "download" { "[DOWN]" }
        "process" { "[RUN]" }
        "warn" { "[WARN]" }
        "error" { "[FAIL]" }
        "path" { "[PATH]" }
        default { "[*]" }
    }

    $color = switch ($Type) {
        "info" { "Cyan" }
        "success" { "Green" }
        "download" { "Yellow" }
        "process" { "Magenta" }
        "warn" { "DarkYellow" }
        "error" { "Red" }
        "path" { "DarkGray" }
        default { "White" }
    }

    Write-Host ($prefix + " ") -NoNewline -ForegroundColor $color
    Write-Host $Message -ForegroundColor White
}

function Show-Intro {
    Show-Status "Paste one link. The script auto-detects source and download mode." "info"
    Show-Status "YouTube video: best video + MP3" "info"
    Show-Status "YouTube Music: MP3 only" "info"
    Show-Status "Facebook video: video + MP3 when available" "info"
    Show-Status "Library root: $libraryDir" "path"
    Show-Status "Type 'exit' to quit." "path"
}

function Get-SourceInfo {
    param(
        [string]$Url
    )

    if ($Url -match '(youtube\.com|youtu\.be)') {
        $isMusic = $Url -match 'music\.youtube\.com'
        return @{
            Name = "YouTube"
            Key = "YouTube"
            DownloadAudio = $true
            DownloadVideo = (-not $isMusic)
            ModeLabel = if ($isMusic) { "Audio only" } else { "Best video + MP3" }
        }
    }

    if ($Url -match '(facebook\.com|fb\.watch)') {
        return @{
            Name = "Facebook"
            Key = "Facebook"
            DownloadAudio = $true
            DownloadVideo = $true
            ModeLabel = "Video + MP3"
        }
    }

    return @{
        Name = "Other"
        Key = "Other"
        DownloadAudio = $true
        DownloadVideo = $true
        ModeLabel = "Best video + MP3"
    }
}

function Get-OutputTemplate {
    param(
        [string]$PlatformKey,
        [string]$MediaType
    )

    $targetDir = Join-Path $libraryDir $PlatformKey
    $targetDir = Join-Path $targetDir $MediaType
    $targetDir = Join-Path $targetDir $sessionStamp

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    return (Join-Path $targetDir "%(title)s.%(ext)s")
}

function Get-LibraryPath {
    param(
        [string]$PlatformKey,
        [string]$MediaType
    )

    $targetDir = Join-Path $libraryDir $PlatformKey
    $targetDir = Join-Path $targetDir $MediaType
    return (Join-Path $targetDir $sessionStamp)
}

function Get-VideoFormatSelector {
    return "bv*[ext=mp4]+ba[ext=m4a]/bv*+ba/b[ext=mp4]/b"
}

function Invoke-AudioDownload {
    param(
        [string]$Url,
        [string]$OutputTemplate
    )

    & $ytDlp `
        -x `
        --audio-format mp3 `
        --audio-quality 0 `
        --yes-playlist `
        --no-warnings `
        --no-progress `
        --quiet `
        --ffmpeg-location $binDir `
        -o $OutputTemplate `
        $Url 2>&1 | Out-Null

    return ($LASTEXITCODE -eq 0)
}

function Invoke-VideoDownload {
    param(
        [string]$Url,
        [string]$OutputTemplate
    )

    & $ytDlp `
        -f (Get-VideoFormatSelector) `
        --merge-output-format mp4 `
        --yes-playlist `
        --no-warnings `
        --no-progress `
        --quiet `
        --ffmpeg-location $binDir `
        -o $OutputTemplate `
        $Url 2>&1 | Out-Null

    return ($LASTEXITCODE -eq 0)
}

New-Item -ItemType Directory -Force -Path $binDir, $libraryDir | Out-Null

if (-not (Test-Path $ytDlp)) {
    Show-Status "Installing yt-dlp..." "download"
    Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $ytDlp -UseBasicParsing -ErrorAction Stop | Out-Null
    Show-Status "yt-dlp installed successfully" "success"
}
else {
    Show-Status "yt-dlp ready" "success"
}

if (-not (Test-Path $ffmpeg)) {
    Show-Status "Installing ffmpeg..." "download"
    $zip = Join-Path $binDir "ffmpeg.zip"

    Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $zip -UseBasicParsing -ErrorAction Stop | Out-Null
    Expand-Archive $zip -DestinationPath $binDir -Force | Out-Null
    Remove-Item $zip -Force

    $ffmpegExe = Get-ChildItem $binDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    if ($ffmpegExe) {
        Copy-Item $ffmpegExe.FullName $ffmpeg -Force
        Get-ChildItem $binDir -Directory | Remove-Item -Recurse -Force
        Show-Status "ffmpeg installed successfully" "success"
    }
    else {
        Show-Status "ffmpeg installation failed" "error"
        exit
    }
}
else {
    Show-Status "ffmpeg ready" "success"
}

$downloadCount = 0

Show-Intro

while ($true) {
    Write-Host ""
    $url = Read-Host "Paste media link"

    if ($url -match '^(exit|quit|q)$') {
        Clear-Host
        Show-Status "Session complete. Saved $downloadCount file set(s)." "success"
        Show-Status "Library: $libraryDir" "path"
        Start-Sleep -Seconds 2
        exit
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        continue
    }

    $sourceInfo = Get-SourceInfo -Url $url
    $isPlaylist = $url -match '([?&]list=|/playlist\?)'
    $audioSuccess = $false
    $videoSuccess = $false

    Show-Status ("Source detected: " + $sourceInfo.Name) "info"
    Show-Status ("Auto mode: " + $sourceInfo.ModeLabel) "process"

    if ($isPlaylist) {
        Show-Status "Playlist detected. Processing all available items." "warn"
    }

    try {
        if ($sourceInfo.DownloadVideo) {
            $videoOutput = Get-OutputTemplate -PlatformKey $sourceInfo.Key -MediaType "Video"
            Show-Status "Downloading best video quality..." "download"
            $videoSuccess = Invoke-VideoDownload -Url $url -OutputTemplate $videoOutput
        }

        if ($sourceInfo.DownloadAudio) {
            $audioOutput = Get-OutputTemplate -PlatformKey $sourceInfo.Key -MediaType "MP3"
            Show-Status "Extracting MP3..." "download"
            $audioSuccess = Invoke-AudioDownload -Url $url -OutputTemplate $audioOutput
        }
    }
    catch {
        $audioSuccess = $false
        $videoSuccess = $false
    }

    Clear-Host
    Show-Intro

    if ($sourceInfo.DownloadVideo -and $sourceInfo.DownloadAudio) {
        if ($videoSuccess -and $audioSuccess) {
            $downloadCount++
            Show-Status "Saved video and MP3 successfully." "success"
        }
        elseif ($videoSuccess -or $audioSuccess) {
            $downloadCount++
            Show-Status "Partial success. One format was saved, one failed." "warn"
        }
        else {
            Show-Status "Download failed." "error"
        }
    }
    elseif ($audioSuccess) {
        $downloadCount++
        Show-Status "MP3 saved successfully." "success"
    }
    elseif ($videoSuccess) {
        $downloadCount++
        Show-Status "Video saved successfully." "success"
    }
    else {
        Show-Status "Download failed." "error"
    }

    if ($sourceInfo.DownloadAudio) {
        Show-Status ("MP3 folder: " + (Get-LibraryPath -PlatformKey $sourceInfo.Key -MediaType "MP3")) "path"
    }

    if ($sourceInfo.DownloadVideo) {
        Show-Status ("Video folder: " + (Get-LibraryPath -PlatformKey $sourceInfo.Key -MediaType "Video")) "path"
    }
}
