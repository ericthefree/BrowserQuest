# BrowserQuest for Android

This project packages the existing HTML5 game in a native Kotlin `WebView`. Like the `ios/` WKWebView app, it runs the local single-player world entirely on the device and does not require the Node.js server or a network connection while playing.

## Run in Android Studio

1. Open the `android/` directory in Android Studio Ladybug (2024.2.1) or newer.
2. Install Android SDK 35 when prompted and use the bundled JDK 17.
3. Let Gradle sync, then select the **app** configuration and an Android device or emulator.
4. Run the app. It requires Android 8.0 (API 26) or newer and launches in landscape mode.

The application ID is `com.webquest.game`.

## Assets and offline behavior

The Gradle `syncWebAssets` task copies `client/` and `shared/` into generated build assets while preserving their paths. They are not duplicated in this folder or committed twice. `WebView` serves those files from the private `https://browserquest.local` app origin, and a native bridge injects the same offline globals used by the iOS wrapper before the game's JavaScript runs.

JavaScript, CSS, maps, sprites, sound effects, and the local game simulation are therefore bundled in the APK. External links open in the user's browser.

## Saves

Character data, equipment, achievements, checkpoints, and offline world state are mirrored from JavaScript into native `SharedPreferences`. Android Auto Backup includes only that save file, allowing Google account backup and device-to-device transfer when those system features are enabled. Local Web Storage remains available as an additional on-device copy.

This does not use Google Play Games Saved Games and requires no Google API credentials.

## Controls and debugging

The same responsive layout, touch-drag movement, room framing, and tap interactions used by the iOS web-wrapper build are shared from `client/`.

Debug builds enable WebView inspection. Connect the device and open `chrome://inspect` in desktop Chrome to inspect the game. Native and forwarded JavaScript messages use the `BrowserQuest` tags in Logcat.

## Command-line build

With JDK 17 and Android SDK 35 installed:

```sh
cd android
./gradlew assembleDebug
```

The APK is written to `app/build/outputs/apk/debug/app-debug.apk`.
