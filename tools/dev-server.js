#!/usr/bin/env node

"use strict";

const fs = require("fs");
const http = require("http");
const net = require("net");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

const root = path.resolve(__dirname, "..");
const port = Number(process.env.PORT || 8080);
const gamePort = Number(process.env.GAME_PORT || 8000);
const mimeTypes = {
    ".css": "text/css; charset=utf-8",
    ".eot": "application/vnd.ms-fontobject",
    ".html": "text/html; charset=utf-8",
    ".ico": "image/x-icon",
    ".jpeg": "image/jpeg",
    ".jpg": "image/jpeg",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".mp3": "audio/mpeg",
    ".ogg": "audio/ogg",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".ttf": "font/ttf",
    ".wav": "audio/wav",
    ".woff": "font/woff"
};

const gameConfig = JSON.parse(fs.readFileSync(path.join(root, "server/config.json"), "utf8"));
gameConfig.port = gamePort;
const generatedConfig = path.join(os.tmpdir(), `browserquest-server-${process.pid}.json`);
fs.writeFileSync(generatedConfig, JSON.stringify(gameConfig));

const game = spawn(process.execPath, ["server/js/main.js", generatedConfig], {
    cwd: root,
    stdio: "inherit"
});

function sendFile(requestPath, response) {
    let pathname;
    try {
        pathname = decodeURIComponent(new URL(requestPath, "http://localhost").pathname);
    } catch (error) {
        response.writeHead(400).end("Bad request");
        return;
    }

    if (pathname === "/") {
        pathname = "/index.html";
    }

    const filename = path.resolve(root, `.${pathname}`);
    if (filename !== root && !filename.startsWith(`${root}${path.sep}`)) {
        response.writeHead(403).end("Forbidden");
        return;
    }

    fs.stat(filename, (error, stats) => {
        if (error || !stats.isFile()) {
            response.writeHead(404).end("Not found");
            return;
        }

        response.writeHead(200, {
            "Content-Type": mimeTypes[path.extname(filename).toLowerCase()] || "application/octet-stream",
            "Cache-Control": "no-cache"
        });
        fs.createReadStream(filename).pipe(response);
    });
}

const server = http.createServer((request, response) => {
    if (request.url === "/healthz") {
        response.writeHead(200, { "Content-Type": "text/plain" }).end("ok");
        return;
    }
    sendFile(request.url, response);
});

server.on("upgrade", (request, socket, head) => {
    const upstream = net.connect(gamePort, "127.0.0.1");
    upstream.on("connect", () => {
        upstream.write(`${request.method} ${request.url} HTTP/${request.httpVersion}\r\n`);
        for (let index = 0; index < request.rawHeaders.length; index += 2) {
            upstream.write(`${request.rawHeaders[index]}: ${request.rawHeaders[index + 1]}\r\n`);
        }
        upstream.write("\r\n");
        if (head.length) {
            upstream.write(head);
        }
        socket.pipe(upstream).pipe(socket);
    });
    upstream.on("error", () => socket.destroy());
});

server.listen(port, "0.0.0.0", () => {
    console.log(`BrowserQuest development server listening on port ${port}`);
});

function shutdown() {
    server.close();
    game.kill("SIGTERM");
    try {
        fs.unlinkSync(generatedConfig);
    } catch (error) {
        if (error.code !== "ENOENT") {
            throw error;
        }
    }
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
game.on("exit", (code, signal) => {
    if (code !== 0 && signal !== "SIGTERM") {
        server.close(() => process.exit(code || 1));
    }
});
