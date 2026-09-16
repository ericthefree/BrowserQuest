# BrowserQuest for iOS

This project packages the HTML5 client in a native `WKWebView` and runs a local single-player world simulation. The iOS app does not require the Node.js server or a network connection to play.

## Run in Xcode

1. Open `BrowserQuest.xcodeproj` in Xcode 15 or newer.
2. Select the **BrowserQuest** scheme and an iPhone or iPad simulator.
3. Select the BrowserQuest target, choose your development team under **Signing & Capabilities**, and ensure the iCloud capability has **Key-value storage** enabled.
4. Run the app.

Character identity, equipment, achievements, and the latest checkpoint are saved through `NSUbiquitousKeyValueStore`. iCloud data is restored when the app starts. The web client also retains its local save, so gameplay still works when iCloud is unavailable.

Bundled game files are served to `WKWebView` through the app's private `browserquest://` URL scheme. This avoids device sandbox-extension failures from direct `file://` loading. JavaScript and navigation failures are printed in Xcode with a `[BrowserQuest JS]` or `[BrowserQuest navigation]` prefix.

The `client` and `shared` directories are Xcode folder references. Changes to web assets are therefore picked up without manually editing the project file.
