BrowserQuest client documentation
=================================

Local development
------------------

For local development no build step is needed — the client loads its source
files directly via RequireJS. Running `../bin/setup.sh` from the project
root handles all of this automatically (see the root README).

To do it by hand instead:

1) Copy `client/config/config_local.json-dist` to `client/config/config_local.json`
and set `host` to your game server's address (e.g. `localhost`).

2) Serve the **project root** (not the `client/` directory) as static files,
e.g. `python3 -m http.server 8080` run from the project root, then open
`http://localhost:8080/client/index.html`. The project root matters because
`client/js/game.js` reaches `shared/js/gametypes.js` via a path relative to
it (`../../shared/js/gametypes`) — serving only `client/` breaks that.

3) Start the game server separately (`node server/js/main.js` from the
project root) — see the server README.


Production build
-----------------

The client directory should never be directly deployed to staging/production. Deployment steps:

1) Configure the websocket host/port:

In the client/config/ directory, copy config_build.json-dist to a new config_build.json file.
Edit the contents of this file to change host/port settings.

2) Run the following commands from the project root:

(Note: nodejs is required to run the build script)

* cd bin
* chmod +x build.sh
* ./build.sh

This will use the RequireJS optimizer tool to create a client-build/ directory containing a production-ready version of BrowserQuest. 

A build log file will also be created at bin/build.txt.

The client-build directory can be renamed and deployed anywhere. It has no dependencies to any other file/folder in the repository.