# BrowserQuest for iOS

This project packages the existing HTML5 client in a native `WKWebView`. The multiplayer server remains the Node.js service in `server/`; it is not embedded in the app.

## Run in Xcode

1. Open `BrowserQuest.xcodeproj` in Xcode 15 or newer.
2. Select the **BrowserQuest** scheme and an iPhone or iPad simulator.
3. Start the game server from the repository root with `npm start`.
4. Run the app.

The checked-in development setting connects to `ws://localhost:8000`, which works in the iOS Simulator. For a physical device, change `BrowserQuestServerURL` in `BrowserQuest/Info.plist` to a server the device can reach, such as `ws://192.168.1.10:8000`. Use `wss://` for distributed builds.

The `client` and `shared` directories are Xcode folder references. Changes to web assets are therefore picked up without manually editing the project file.
