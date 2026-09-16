# BrowserQuest Native for iOS

This folder contains a separate, fully native iOS client built with Swift, UIKit, and SpriteKit. It does not use `WKWebView`, JavaScript, the Node server, or a network connection. The existing web-wrapper app remains in `ios/`.

The native client reads the original BrowserQuest maps, sprite definitions, pixel art, and sounds directly from `client/`. The Xcode project includes that folder as a bundled resource, so asset changes made for the web game are available to both clients.

## Run in Xcode

1. Open `ios-native/BrowserQuestNative.xcodeproj` in Xcode 16 or newer.
2. Select the **BrowserQuestNative** target, then **Signing & Capabilities**.
3. Select your Development Team. The bundle identifier defaults to `com.web-quest.game.native`; change it if that identifier is unavailable to your team.
4. Add the **iCloud** capability and enable **Key-value storage**. Xcode should retain the existing `com.apple.developer.ubiquity-kvstore-identifier` entitlement.
5. Choose an iPhone or iPad running iOS 16 or newer and press Run.

The game still runs without an iCloud account. Saves always go to `UserDefaults` and are mirrored to iCloud key-value storage when it is available.

## Controls

- Drag anywhere and hold to move in any direction. Collision resolution allows the player to slide along walls.
- Tap a nearby enemy to attack it.
- Tap an NPC or chest to interact.
- Walk over an item to collect it.

## Native systems

- SpriteKit tile-map rendering, including stacked, overhead, and animated tiles
- Original world collision map, doors, teleports, and checkpoints
- Continuous analog movement and a camera that follows the player
- Native sprite-sheet animation for the player, enemies, NPCs, items, and chests
- Static and roaming world entities loaded from the original server map
- Grid pathfinding, enemy pursuit, combat, damage, death, and checkpoint revival
- Item collection, healing, armor/weapon state, and native audio playback
- Local persistence with iCloud key-value synchronization
- Native HUD and touch interaction

This is a single-player native engine, not a wrapper around the browser client. BrowserQuest's original multiplayer protocol, chat, achievements, scripted NPC dialog, loot tables, and complete quest progression are not part of this first native version. Those systems can be added directly in Swift without changing the native rendering and input foundation.

## Project layout

```text
ios-native/
├── BrowserQuestNative.xcodeproj/
└── BrowserQuestNative/
    ├── GameScene.swift          SpriteKit game loop and gameplay
    ├── TileMapRenderer.swift    Original tile-sheet rendering
    ├── MapModel.swift           Client/server map decoding and collision
    ├── Pathfinder.swift         Native grid pathfinding
    ├── SpriteFactory.swift      Original sprite-sheet decoding
    ├── EntityModel.swift        Entity roles and combat stats
    ├── SaveStore.swift          Local and iCloud persistence
    └── AudioManager.swift       Original sound playback
```
