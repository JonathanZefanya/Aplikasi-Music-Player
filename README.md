# Music

Music is a local music player app that plays music from your device built with Flutter.

## Platforms

- Android

## Features

- Play music from your device
- Background audio
- Notification controls
- Lock screen controls
- Play, pause, skip, previous, seek
- Shuffle and repeat
- Search for music, artists, albums, genres
- Sort by (title, artist, album, duration, date, size, etc)
- Order by (ascending, descending)
- Favorites (Add songs, remove songs)
- Recently played
- Artists
- Albums
- Genres
- Share music
- Settings
- Themes (multiple themes)

## Installation

### Prerequisites

- Flutter
- Visual Studio Code / Android Studio 

### Setup

1. Clone the repo

   ```sh
   git clone https://github.com/JonathanZefanya/Aplikasi-Music-Player
   ```

2. Install dependencies

   ```sh
   flutter pub get
   ```

3. Run the app

   ```sh
   flutter run
   ```

## Permissions

### Android

```xml

<!-- url_launcher -->
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
</queries>

<!-- !DANGER! Delete, update songs/playlists -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

<!-- Android 12 or below  -->
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"
/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 13 or greater  -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Audio service -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```