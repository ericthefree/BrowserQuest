BrowserQuest
============

BrowserQuest is a HTML5/JavaScript multiplayer game experiment.


Quick Start
-----------

Requires [Node.js](https://nodejs.org) and Python 3.

    ./bin/setup.sh

This installs dependencies, starts the game server and a local client server,
and opens the game in your browser at `http://localhost:8080`. Press
`Ctrl+C` to stop both servers.

In an Amp orb, dependencies are installed by `.agents/setup`. Run
`amp orb services ensure` to start the supervised game server and print its
browser portal.


iOS
---

Two offline, single-player Xcode projects are available:

- `ios/BrowserQuest.xcodeproj` packages the web client with `WKWebView`.
- `ios-native/BrowserQuestNative.xcodeproj` is a native Swift and SpriteKit
  game engine that reuses the original maps, artwork, and audio without a web
  view or JavaScript runtime.

Both sync saves through iCloud. See each folder's README for signing, iCloud,
and run instructions.


Android
-------

The `android/` project packages the offline web client in a native Kotlin
`WebView`, with native save backup and the same touch controls as the iOS web
wrapper. See `android/README.md` for Android Studio and device instructions.


Documentation
-------------

Documentation is located in client and server directories. The current
browser and server review is in `CODE_REVIEW.md`.


License
-------

Code is licensed under MPL 2.0. Content is licensed under CC-BY-SA 3.0.
See the LICENSE file for details.


Credits
-------
Created by [Little Workshop](http://www.littleworkshop.fr):

* Franck Lecollinet - [@whatthefranck](http://twitter.com/whatthefranck)
* Guillaume Lecollinet - [@glecollinet](http://twitter.com/glecollinet)
