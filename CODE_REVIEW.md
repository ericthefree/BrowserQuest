# BrowserQuest code review

Reviewed 2026-09-16 against the browser client, Node.js multiplayer server, shared protocol, development scripts, and a live Chromium playthrough.

## Summary

The client renders and the core multiplayer loop works, but the server trusts client claims for nearly every gameplay action. That architecture is not safe for an untrusted public multiplayer deployment. The highest-priority follow-up is a server-authoritative gameplay pass, followed by connection limits and action throttling.

The fresh-checkout startup failure, modern jQuery character-name failure, and secure WebSocket compatibility issue found during this review were fixed as part of the orb/iOS work.

## Findings

### Critical: gameplay is client-authoritative

`server/js/player.js:86-220` accepts movement, combat, loot, teleport, chest, and checkpoint messages after validating their shape, but does not consistently validate distance, path continuity, timing, target state, ownership, portal origin, or checkpoint containment. Related global mutations are in `server/js/worldserver.js:465-477,526-559,600-605,834-842`.

A modified client can move to arbitrary walkable tiles, damage or loot known entity IDs remotely, open distant chests, and choose checkpoints. Make the server own movement timing, attack targets/cooldowns, interaction range, portal transitions, inventory, and progression before exposing it to adversarial players.

### Critical: the client chooses starting equipment

`server/js/player.js:47-65` passes armor and weapon kinds from `HELLO` directly to the equip methods. A raw WebSocket test joined with golden armor (26) and golden sword (63), and the server accepted the loadout with 230 HP.

Ignore equipment in `HELLO`; force starter gear or load server-owned progression. Later equipment changes must be checked against server-owned inventory.

### High: idle pre-handshake sockets have no deadline or capacity limit

`server/js/ws.js:136-148` stores accepted sockets, while `server/js/player.js:379-386` starts the inactivity timeout only after a valid inbound game message. A client can receive `go` and remain connected indefinitely without joining a world. Pending sockets are not included in world capacity.

Add a short handshake deadline, total/pending connection caps, and per-IP limits.

### High: dead players can send `HELLO` again

`server/js/player.js:36-67` rejects a repeated `HELLO` only while the player is not dead. A dead connection can rerun join initialization, choose equipment again, and re-enter world bookkeeping.

Reject every second `HELLO`; use a separate server-controlled respawn action.

### High: actions have no rate limits or authoritative cooldowns

`server/js/ws.js:186-203` processes every frame immediately and `server/js/player.js:27-228` has no per-action throttling. Combat messages can be emitted at network speed, and `WHO` can repeatedly request arbitrary ID lists.

Add bounded message sizes, per-action token buckets, combat cooldowns, and disconnect thresholds.

### Medium: full worlds leave accepted connections hanging

In `server/js/main.js:39-61`, `_.detect` returns no world when all instances are full. The accepted WebSocket is neither answered nor closed, so the user hangs and the connection remains allocated.

Return a structured `FULL` response and close immediately.

### Medium: entity access is global, not visibility-scoped

The action handlers in `server/js/player.js:69-72,104-105,119-140,153-155,212-214` resolve IDs from the global entity table. Guessed or previously observed IDs can be queried and acted on outside the player's visible groups.

Require the entity to be in server-computed visibility and interaction range.

### Medium: corrupt browser storage prevents startup

`client/js/storage.js:5-10` parses `localStorage.data` without error handling or schema validation. Truncated or obsolete data throws during app construction, requiring users to manually clear site data.

Catch parse failures, validate the stored shape, and reset invalid data.

### Low: position equality ignores one Y coordinate

`server/js/map.js:216-218` compares `pos2.y === pos2.y`, which is always true. Door-linked groups sharing an X coordinate can be incorrectly deduplicated.

Compare `pos1.y === pos2.y`.

### Low: referenced music is absent

`client/js/audio.js:14,31-40,100-105` requests seven tracks under `client/audio/music/`, but that directory is intentionally absent from the repository. Music requests fail while sound effects continue to work.

Add appropriately licensed tracks or explicitly disable those music entries.

### Low: touch handling can conflict with browser gestures

`client/js/main.js:253-259` handles touch without deliberately suppressing browser gestures, and the gameplay surface has no `touch-action` policy. This is a traced compatibility risk rather than a device-verified failure.

Prefer Pointer Events and set an intentional `touch-action` value on the canvas.

## Verification performed

- Started the Node.js server and static client and checked `/status`.
- Loaded the game in Chromium, created a character, and confirmed the map, player, HUD, and WebSocket-backed game state rendered.
- Used a raw WebSocket client to verify the arbitrary starting-equipment finding.
- Ran `npm audit`; it reported zero known vulnerabilities in the current dependency tree.
