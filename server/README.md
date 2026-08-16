BrowserQuest server documentation
=================================

The game server runs on Node.js (tested with v22) and requires the following npm packages:

- underscore
- log
- bison
- websocket
- sanitizer
- memcache (only if you want metrics)

All of them can be installed via `npm install` from the project root (this will install a local copy of all the dependencies in the node_modules directory).

Running `../bin/setup.sh` from the project root does this automatically, along with setting up a working `config_local.json` and starting the server — see the root README for the quick-start path.


Configuration
-------------

The server settings (number of worlds, number of players per world, etc.) can be configured.
Copy `config.json` to a new `config_local.json` file in this directory, then edit it. The server will override default settings with this file.


Deployment
----------

In order to deploy the server, simply copy the `server` and `shared` directories to the staging/production server.

Then run `node server/js/main.js` in order to start the server.


Note: the `shared` directory is the only one in the project which is a server dependency.


Monitoring
----------

The server has a status URL which can be used as a health check or simply as a way to monitor player population.

Send a GET request to: `http://[host]:[port]/status`

It will return a JSON array containing the number of players in all instanced worlds on this game server.
