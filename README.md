# Media Grabber Console

## Features

- **Zero Configuration** - Automatically downloads and installs dependencies (yt-dlp & ffmpeg)
- **Paste-Only Flow** - Paste one link and the script auto-detects what to do
- **Auto Save Both Formats** - For normal video links it saves best video and MP3 together
- **Max Quality YouTube Video** - Uses the best available video quality instead of capping at 720p
- **YouTube and Facebook Support** - Works with supported links from both platforms
- **Cleaner CLI** - Styled terminal output with a more polished dashboard feel
- **Continuous Mode** - Download multiple files without restarting
- **Playlist Support** - Download entire playlists or single videos when supported
- **Silent Operation** - No cluttered logs, only essential feedback
- **Organized Library** - Files are grouped by platform, format, and month inside `library/`

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Internet connection

## Quick Start

1. Download scripts:

- Option 1: clone this repo and after run file `yt.ps1`
- Option 2: create a folder - copy content in file `yt.ps1`
- Option 3: download file script `yt.ps1` from release page at [here](https://github.com/baiyuechuz/ytb_mp3_downloader/releases/tag/script_file) to a folder

2. Open terminal and run the script:
   ```powershell
   .\yt.ps1
   ```

3. Paste a YouTube or Facebook URL when prompted
4. Type `exit` to quit

That's it! Dependencies are installed automatically on first run.

## Usage

### Basic Usage

```powershell
.\yt.ps1
```

The script will:
1. Show a welcome banner
2. Auto-install yt-dlp and ffmpeg (first run only)
3. Prompt for a YouTube or Facebook URL
4. Auto-detect the source and download mode
5. Save files into the organized `library/` folders

### Commands

- **Paste a YouTube video URL** - Saves best video quality and MP3
- **Paste a YouTube Music URL** - Saves MP3 only
- **Paste a Facebook video URL** - Tries to save video and MP3
- **Paste a supported playlist URL** - Downloads all available items into the matching folders
- **`exit`** / **`quit`** / **`q`** - Exit the program

## File Structure

```
your-folder/
├── yt.ps1          # Main script
├── bin/            # Auto-created, contains yt-dlp.exe & ffmpeg.exe
└── library/
    ├── YouTube/
    │   ├── MP3/
    │   └── Video/
    ├── Facebook/
    │   ├── MP3/
    │   └── Video/
    └── Other/
        ├── MP3/
        └── Video/
```

## How It Works

1. **Dependencies Check** - On first run, downloads:
   - [yt-dlp](https://github.com/yt-dlp/yt-dlp) - YouTube downloader
   - [ffmpeg](https://ffmpeg.org/) - Audio converter

2. **Detect** - Checks whether the link is YouTube, YouTube Music, Facebook, or another supported source

3. **Download** - Pulls the best available video and/or extracts MP3 depending on the detected source

4. **Save** - Stores everything in `library/<platform>/<format>/<yyyy-MM>/`

## Advanced

### Auto Detection

The script uses this default behavior:

- `music.youtube.com` links: MP3 only
- Standard YouTube video links: best video quality + MP3
- Facebook video links: video + MP3 when available
- Other supported links: best video quality + MP3

### Output Location

To change the main output location, edit the directory variable near the top of the script:

```powershell
$libraryDir = "$baseDir\library"
```

### Playlists

Paste a supported playlist URL and the script will automatically download all items in the selected format. Works with:
- Public playlists
- Your own playlists (if public)
- Mix playlists
- Channel playlists

Example playlist URLs:
```
https://www.youtube.com/playlist?list=PLxxxxxxxxxxxxxxxxxx
https://www.youtube.com/watch?v=xxxxx&list=PLxxxxxxxxxxxxxxxxxx
```

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Video/audio downloader
- [ffmpeg](https://ffmpeg.org/) - Media processing

---

**Paste one link. The script handles the rest.**
