# Music

Music is a local music player app that plays music from your device built with Flutter.

## Platforms

- Android

## Features
Look At [FEATURE.md](FEATURE.md)

## Installation

### Prerequisites

- Flutter ersion 3.41.5
- Visual Studio Code / Android Studio 
- Emulator Android 14

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
