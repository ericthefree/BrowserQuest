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

An Xcode project that packages the web client with `WKWebView` is available in
`ios/BrowserQuest.xcodeproj`. It runs as an offline single-player game and
syncs saves through iCloud. See `ios/README.md` for signing and iCloud setup.


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
