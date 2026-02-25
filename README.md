# VidBox - Video & Music Downloader

A professional Flutter application for downloading videos and music from multiple social media platforms including YouTube, Instagram, TikTok, Facebook, Twitter, and Vimeo.

## Features

### Core Features
- 🎥 Download videos from multiple platforms
- 🎵 Extract and download audio/music
- 📱 Support for YouTube, Instagram, TikTok, Facebook, Twitter, Vimeo
- 🎨 Beautiful Material Design 3 UI
- 🌓 Dark Mode support
- 📊 Real-time download progress
- 🔔 System notifications for downloads
- 📁 Organized file storage in custom folder
- ⏸️ Pause, resume, and cancel downloads
- 🔄 Retry failed downloads
- 📜 Download history
- ▶️ Play downloaded media directly from app
- 🔍 Duplicate detection

### Technical Features
- GetX State Management
- Supabase Backend Integration
- Clean Architecture (MVC Pattern)
- Efficient Download Queue Management
- Permission Handling
- Local Notifications
- File Management
- Responsive UI

## Project Structure

```
lib/
├── core/
│   ├── routes/           # App navigation
│   ├── services/         # Core services
│   │   ├── database_service.dart
│   │   ├── download_service.dart
│   │   ├── notification_service.dart
│   │   ├── permission_service.dart
│   │   ├── storage_service.dart
│   │   └── video_info_service.dart
│   ├── theme/           # App theming
│   └── utils/           # Constants & utilities
├── data/
│   └── models/          # Data models
├── modules/
│   ├── main/            # Main navigation
│   ├── home/            # Home screen (URL input)
│   └── downloads/       # Downloads screen
└── main.dart            # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code
- Supabase Account

### Installation

1. **Clone or create the project**
   ```bash
   flutter create vidbox
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   Create a Supabase project and set up the database:

   ```sql
   CREATE TABLE downloads (
     id TEXT PRIMARY KEY,
     url TEXT NOT NULL,
     title TEXT NOT NULL,
     thumbnail TEXT,
     type TEXT NOT NULL,
     quality TEXT NOT NULL,
     status TEXT NOT NULL,
     progress INTEGER DEFAULT 0,
     file_path TEXT,
     platform TEXT NOT NULL,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW()
   );

   ALTER TABLE downloads ENABLE ROW LEVEL SECURITY;

   CREATE POLICY "Allow all operations"
     ON downloads
     FOR ALL
     TO anon
     USING (true)
     WITH CHECK (true);
   ```

4. **Update Supabase credentials**

   Edit `lib/core/utils/constants.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Download Video/Audio

1. Open the app
2. Paste or enter a video URL
3. Tap "Paste & Fetch Info"
4. Select Video or Audio
5. Choose quality
6. Tap "Start Download"

### View Downloads

1. Navigate to "Downloads" tab
2. See active downloads with progress
3. View completed downloads in history
4. Tap to play downloaded media

### Manage Downloads

- **Pause**: Tap pause button on active download
- **Resume**: Tap resume button on paused download
- **Cancel**: Tap cancel to stop download
- **Retry**: Tap retry on failed downloads
- **Delete**: Use menu to delete from history
- **Play**: Tap completed download to play

## Permissions

The app requires the following permissions:
- Storage (Read/Write)
- Internet
- Notifications
- Media Library (Android 13+)

All permissions are requested automatically on first launch.

## Configuration

### Download Location
Files are saved in: `{Storage}/VidBox Downloads/`

### Supported Platforms
- YouTube (fully functional with youtube_explode_dart)
- Instagram (placeholder - requires implementation)
- TikTok (placeholder - requires implementation)
- Facebook (placeholder - requires implementation)
- Twitter (placeholder - requires implementation)
- Vimeo (placeholder - requires implementation)

### Quality Options

**Video:**
- 2160p (4K)
- 1440p (2K)
- 1080p (Full HD)
- 720p (HD)
- 480p
- 360p

**Audio:**
- 320kbps
- 256kbps
- 192kbps
- 128kbps

## Dependencies

```yaml
dependencies:
  get: ^4.6.6                            # State management
  supabase_flutter: ^2.0.0               # Database
  youtube_explode_dart: ^2.0.0           # YouTube support
  permission_handler: ^11.0.1            # Permissions
  flutter_local_notifications: ^16.2.0   # Notifications
  video_player: ^2.8.1                   # Video playback
  just_audio: ^0.9.36                    # Audio playback
  dio: ^5.4.0                            # Network requests
  cached_network_image: ^3.3.0           # Image caching
  path_provider: ^2.1.1                  # File paths
  open_filex: ^4.3.4                     # File opening
```

## Building for Release

### Android

1. **Generate keystore**
   ```bash
   keytool -genkey -v -keystore ~/vidbox-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vidbox
   ```

2. **Configure signing**

   Create `android/key.properties`:
   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=vidbox
   storeFile=<path-to-keystore>
   ```

3. **Build APK**
   ```bash
   flutter build apk --release
   ```

4. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

## Known Limitations

1. **YouTube Only**: Currently only YouTube downloads are fully functional. Other platforms require API implementation.

2. **Android Only**: iOS support requires additional configuration and may have App Store restrictions.

3. **Download Speed**: Depends on internet connection and source server.

4. **File Size**: Large files (>2GB) may have issues on some devices.

## Future Enhancements

- [ ] Implement Instagram downloader
- [ ] Implement TikTok downloader
- [ ] Implement Facebook downloader
- [ ] Add batch download support
- [ ] Add download scheduler
- [ ] Add playlist download
- [ ] Add subtitle download
- [ ] Add format converter
- [ ] Add cloud storage integration
- [ ] iOS support

## Troubleshooting

### Permission Issues
- Go to Settings > Apps > VidBox > Permissions
- Enable all required permissions

### Download Fails
- Check internet connection
- Verify URL is valid
- Check storage space
- Try different quality

### Video Won't Play
- Ensure file exists in storage
- Check if correct player app is installed
- Verify file is not corrupted

## License

This project is for educational purposes. Please respect copyright laws and platform terms of service.

## Support

For issues and questions:
- Check existing issues
- Create new issue with details
- Include error logs if applicable

---

**Note**: Always respect copyright laws and terms of service of the platforms you're downloading from. Use responsibly.
