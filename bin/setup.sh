#!/bin/bash
# Installs dependencies and runs BrowserQuest locally: the game/WebSocket
# server (server/js/main.js) and a static file server for the client,
# served together so the game "just works" when you open the printed URL.
#
# Usage: bin/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CLIENT_PORT=8080
SERVER_PORT=8000

cd "$ROOT_DIR"

port_in_use() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

if ! command -v node >/dev/null 2>&1; then
    echo "Node.js is required but wasn't found on your PATH. Install it from https://nodejs.org and try again." >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required (used to serve the client) but wasn't found on your PATH." >&2
    exit 1
fi

if port_in_use "$SERVER_PORT"; then
    echo "Port $SERVER_PORT is already in use (needed for the game server). Stop whatever's using it and try again." >&2
    echo "  lsof -nP -iTCP:$SERVER_PORT -sTCP:LISTEN" >&2
    exit 1
fi

if port_in_use "$CLIENT_PORT"; then
    echo "Port $CLIENT_PORT is already in use (needed for the client). Stop whatever's using it and try again." >&2
    echo "  lsof -nP -iTCP:$CLIENT_PORT -sTCP:LISTEN" >&2
    exit 1
fi

echo "Installing dependencies..."
npm install

# Local config overrides — gitignored, created once with working defaults
# if they don't already exist.
if [ ! -f server/config_local.json ]; then
    cp server/config.json server/config_local.json
    echo "Created server/config_local.json"
fi

if [ ! -f client/config/config_local.json ]; then
    cat > client/config/config_local.json <<EOF
{
    "host": "localhost",
    "port": $SERVER_PORT,
    "dispatcher": false
}
EOF
    echo "Created client/config/config_local.json"
fi

CLIENT_LOG="$(mktemp -t browserquest-client-log)"

echo "Starting client file server on port $CLIENT_PORT..."
python3 -m http.server "$CLIENT_PORT" > "$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!

cleanup() {
    echo ""
    echo "Stopping servers..."
    kill "$CLIENT_PID" >/dev/null 2>&1
}
trap cleanup EXIT INT TERM

sleep 1

URL="http://localhost:$CLIENT_PORT"
echo ""
echo "BrowserQuest is running: $URL"
echo ""

if command -v open >/dev/null 2>&1; then
    open "$URL"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL"
else
    echo "Open the URL above in your browser to play."
fi

echo "Starting game server on port $SERVER_PORT (Ctrl+C to stop everything)..."
echo ""
node server/js/main.js
