import SpriteKit
import UIKit

final class GameScene: SKScene {
    private let tileSize: CGFloat = 32
    private let playerSpeed: CGFloat = 82
    private let worldNode = SKNode()
    private let gameCamera = SKCameraNode()
    private let spriteFactory = SpriteFactory()
    private let saveStore = SaveStore()
    private let audio = AudioManager()

    private var map: ClientMap!
    private var serverMap: ServerMap!
    private var player: EntityModel!
    private var entities: [String: EntityModel] = [:]
    private var save = NativeSave()
    private var movement = CGVector.zero
    private var touchStart = CGPoint.zero
    private var touchCurrent = CGPoint.zero
    private var touchMoved = false
    private var lastUpdateTime: TimeInterval = 0
    private var lastDoorTime: TimeInterval = 0
    private var lastCheckpointID: Int?

    private let healthLabel = SKLabelNode(fontNamed: "Courier-Bold")
    private let messageLabel = SKLabelNode(fontNamed: "Courier-Bold")

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 37 / 255, green: 34 / 255, blue: 27 / 255, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        do {
            map = try GameDataLoader.load(ClientMap.self, name: "world_client", subdirectory: "client/maps")
            serverMap = try GameDataLoader.load(ServerMap.self, name: "world_server", subdirectory: "client/maps")
            buildWorld()
        } catch {
            showFatalError(error.localizedDescription)
        }
    }

    private func buildWorld() {
        addChild(worldNode)
        let layers = TileMapRenderer.makeLayers(map: map, tileSize: tileSize)
        worldNode.addChild(layers.ground)
        worldNode.addChild(layers.detail)
        worldNode.addChild(layers.overhead)

        save = saveStore.load()
        let checkpoint = map.checkpoints.first { $0.id == save.checkpointID }
            ?? map.checkpoints[0]
        let startX = checkpoint.x + checkpoint.w / 2
        let startY = checkpoint.y + checkpoint.h / 2
        guard let playerNode = spriteFactory.node(kind: save.armor) else {
            showFatalError("Could not load the player sprite.")
            return
        }
        playerNode.position = map.worldPoint(x: startX, y: startY, tileSize: tileSize)
        playerNode.zPosition = 50
        worldNode.addChild(playerNode)
        player = EntityModel(id: "player", kind: save.armor, role: .player, node: playerNode,
                             hitPoints: max(1, save.hitPoints), attackPower: 14)
        player.maxHitPoints = EntityCatalog.playerHitPoints(for: save.armor)
        player.hitPoints = min(player.hitPoints, player.maxHitPoints)
        entities[player.id] = player
        spriteFactory.animate(playerNode, kind: save.armor, animation: "idle_down")

        spawnEntities()
        setupCameraAndHUD()
        updateHealthLabel()
        showMessage("Drag anywhere to move • Tap characters or chests to interact")
    }

    private func setupCameraAndHUD() {
        camera = gameCamera
        addChild(gameCamera)
        gameCamera.position = player.node.position

        healthLabel.fontSize = 18
        healthLabel.horizontalAlignmentMode = .left
        healthLabel.verticalAlignmentMode = .top
        healthLabel.position = CGPoint(x: -size.width / 2 + 24, y: size.height / 2 - 20)
        healthLabel.zPosition = 1000
        gameCamera.addChild(healthLabel)

        messageLabel.fontSize = 16
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .bottom
        messageLabel.position = CGPoint(x: 0, y: -size.height / 2 + 26)
        messageLabel.zPosition = 1000
        gameCamera.addChild(messageLabel)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        healthLabel.position = CGPoint(x: -size.width / 2 + 24, y: size.height / 2 - 20)
        messageLabel.position = CGPoint(x: 0, y: -size.height / 2 + 26)
    }

    private func spawnEntities() {
        var serial = 0
        for (tileString, kind) in serverMap.staticEntities {
            guard let tile = Int(tileString) else { continue }
            let x = ((tile - 1) % map.width) + 1
            let y = (tile - 1) / map.width
            spawn(kind: kind, id: "static-\(serial)", x: x, y: y)
            serial += 1
        }
        for area in serverMap.roamingAreas {
            for index in 0..<area.nb {
                let x = area.x + ((index * 3 + area.id) % max(1, area.width + 1))
                let y = area.y + ((index * 5 + area.id) % max(1, area.height + 1))
                spawn(kind: area.type, id: "roaming-\(area.id)-\(index)", x: x, y: y)
            }
        }
        for (index, chest) in serverMap.staticChests.enumerated() {
            spawn(kind: "chest", id: "chest-\(index)", x: chest.x, y: chest.y)
        }
    }

    private func spawn(kind: String, id: String, x: Int, y: Int) {
        let role = EntityCatalog.role(for: kind)
        let spriteKind = role == .item ? "item-\(kind)" : kind
        guard let node = spriteFactory.node(kind: spriteKind) else { return }
        let stats = EntityCatalog.stats(for: kind)
        node.position = map.worldPoint(x: x, y: y, tileSize: tileSize)
        node.zPosition = 50
        worldNode.addChild(node)
        let entity = EntityModel(id: id, kind: kind, role: role, node: node,
                                 hitPoints: stats.hp, attackPower: stats.attack)
        entities[id] = entity
        let idle = role == .item ? "idle" : "idle_down"
        spriteFactory.animate(node, kind: spriteKind, animation: idle)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStart = touch.location(in: self)
        touchCurrent = touchStart
        touchMoved = false
        movement = .zero
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchCurrent = touch.location(in: self)
        let dx = touchCurrent.x - touchStart.x
        let dy = touchCurrent.y - touchStart.y
        let length = hypot(dx, dy)
        guard length > 14 else { return }
        touchMoved = true
        movement = CGVector(dx: dx / length, dy: dy / length)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !touchMoved, let touch = touches.first {
            interact(at: touch.location(in: self))
        }
        movement = .zero
        touchMoved = false
        setPlayerAnimation(moving: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        movement = .zero
        touchMoved = false
        setPlayerAnimation(moving: false)
    }

    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }
        let deltaTime = lastUpdateTime == 0 ? 0 : min(currentTime - lastUpdateTime, 1 / 20)
        lastUpdateTime = currentTime
        updatePlayer(deltaTime: deltaTime, currentTime: currentTime)
        updateMobs(deltaTime: deltaTime, currentTime: currentTime)
        updateCamera()
        updateCheckpoint()
    }

    private func updatePlayer(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard movement.dx != 0 || movement.dy != 0 else { return }
        let distance = playerSpeed * CGFloat(deltaTime)
        let proposed = CGPoint(x: player.node.position.x + movement.dx * distance,
                               y: player.node.position.y + movement.dy * distance)
        var resolved = player.node.position
        let horizontal = CGPoint(x: proposed.x, y: resolved.y)
        if canOccupy(horizontal) { resolved.x = horizontal.x }
        let vertical = CGPoint(x: resolved.x, y: proposed.y)
        if canOccupy(vertical) { resolved.y = vertical.y }
        player.node.position = resolved
        setPlayerAnimation(moving: true)
        handleDoor(currentTime: currentTime)
        collectNearbyItems()
    }

    private func canOccupy(_ point: CGPoint) -> Bool {
        let radius: CGFloat = 7
        return [CGPoint(x: point.x - radius, y: point.y - radius),
                CGPoint(x: point.x + radius, y: point.y - radius),
                CGPoint(x: point.x - radius, y: point.y + radius),
                CGPoint(x: point.x + radius, y: point.y + radius)].allSatisfy {
            let grid = map.gridPosition(at: $0, tileSize: tileSize)
            return !map.isBlocked(x: grid.x, y: grid.y)
        }
    }

    private func setPlayerAnimation(moving: Bool) {
        let horizontal = abs(movement.dx) > abs(movement.dy)
        let direction: String
        if horizontal {
            direction = "right"
        } else {
            direction = movement.dy >= 0 ? "up" : "down"
        }
        spriteFactory.animate(player.node, kind: save.armor,
                              animation: "\(moving ? "walk" : "idle")_\(direction)",
                              flipped: horizontal && movement.dx < 0)
    }

    private func handleDoor(currentTime: TimeInterval) {
        guard currentTime - lastDoorTime > 0.65 else { return }
        let grid = map.gridPosition(at: player.node.position, tileSize: tileSize)
        guard let door = map.door(x: grid.x, y: grid.y) else { return }
        player.node.position = map.worldPoint(x: door.tx, y: door.ty, tileSize: tileSize)
        lastDoorTime = currentTime
        audio.play(door.p == 1 ? "teleport" : "npc-end")
    }

    private func updateCamera() {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let worldWidth = CGFloat(map.width) * tileSize
        let worldHeight = CGFloat(map.height) * tileSize
        gameCamera.position = CGPoint(
            x: min(max(player.node.position.x, halfWidth), worldWidth - halfWidth),
            y: min(max(player.node.position.y, halfHeight), worldHeight - halfHeight)
        )
    }

    private func updateMobs(deltaTime: TimeInterval, currentTime: TimeInterval) {
        for entity in entities.values where entity.role == .mob {
            let dx = player.node.position.x - entity.node.position.x
            let dy = player.node.position.y - entity.node.position.y
            let distance = hypot(dx, dy)
            guard distance < tileSize * 5 else { continue }
            if distance < tileSize * 0.9 {
                if currentTime - entity.lastAttackTime > 0.9 {
                    entity.lastAttackTime = currentTime
                    damagePlayer(entity.attackPower)
                }
            } else if distance > 0 {
                if currentTime - entity.lastPathTime > 0.3 || entity.nextPathStep == nil {
                    let start = map.gridPosition(at: entity.node.position, tileSize: tileSize)
                    let goal = map.gridPosition(at: player.node.position, tileSize: tileSize)
                    entity.nextPathStep = Pathfinder.nextStep(from: start, to: goal, on: map)
                    entity.lastPathTime = currentTime
                }
                guard let nextStep = entity.nextPathStep else { continue }
                let waypoint = map.worldPoint(x: nextStep.x, y: nextStep.y, tileSize: tileSize)
                let pathDX = waypoint.x - entity.node.position.x
                let pathDY = waypoint.y - entity.node.position.y
                let pathDistance = hypot(pathDX, pathDY)
                let step = CGFloat(deltaTime) * 34
                let candidate = pathDistance <= step
                    ? waypoint
                    : CGPoint(x: entity.node.position.x + (pathDX / pathDistance) * step,
                              y: entity.node.position.y + (pathDY / pathDistance) * step)
                let grid = map.gridPosition(at: candidate, tileSize: tileSize)
                if !map.isBlocked(x: grid.x, y: grid.y) { entity.node.position = candidate }
                if pathDistance <= step { entity.nextPathStep = nil }
                spriteFactory.animate(entity.node, kind: entity.kind, animation: "walk_down")
            }
            entity.node.zPosition = 50 + (CGFloat(map.height) * tileSize - entity.node.position.y) / 100_000
        }
    }

    private func interact(at scenePoint: CGPoint) {
        let worldPoint = convert(scenePoint, to: worldNode)
        let candidates = entities.values.filter { $0.role != .player && $0.node.position.distance(to: worldPoint) < 44 }
        guard let target = candidates.min(by: {
            $0.node.position.distance(to: worldPoint) < $1.node.position.distance(to: worldPoint)
        }) else { return }
        switch target.role {
        case .mob: attack(target)
        case .npc:
            audio.play("npctalk")
            showMessage("\(target.kind.capitalized): Welcome, adventurer!")
        case .chest:
            target.node.removeFromParent()
            entities.removeValue(forKey: target.id)
            audio.play("chest")
            showMessage("You opened a chest.")
        case .item: collect(target)
        case .player: break
        }
    }

    private func attack(_ mob: EntityModel) {
        guard mob.node.position.distance(to: player.node.position) < tileSize * 1.6 else {
            showMessage("Move closer to attack.")
            return
        }
        mob.hitPoints -= player.attackPower
        audio.play("hit1")
        if mob.hitPoints <= 0 {
            mob.node.removeFromParent()
            entities.removeValue(forKey: mob.id)
            audio.play("kill1")
            showMessage("Defeated \(mob.kind).")
        }
    }

    private func collectNearbyItems() {
        let nearbyItems = entities.values.filter {
            $0.role == .item && $0.node.position.distance(to: player.node.position) < tileSize * 0.7
        }
        for entity in nearbyItems {
            collect(entity)
        }
    }

    private func collect(_ item: EntityModel) {
        if item.kind == "flask" || item.kind == "burger" {
            player.hitPoints = min(player.maxHitPoints, player.hitPoints + (item.kind == "flask" ? 40 : 100))
            audio.play("heal")
        } else {
            audio.play("loot")
            if item.kind.contains("armor") {
                save.armor = item.kind
                player.maxHitPoints = EntityCatalog.playerHitPoints(for: item.kind)
                player.hitPoints = player.maxHitPoints
                replacePlayerSprite(with: item.kind)
            } else if EntityCatalog.items.contains(item.kind) {
                save.weapon = item.kind
            }
        }
        item.node.removeFromParent()
        entities.removeValue(forKey: item.id)
        save.hitPoints = player.hitPoints
        saveStore.save(save)
        updateHealthLabel()
        showMessage("Picked up \(item.kind).")
    }

    private func replacePlayerSprite(with armor: String) {
        guard let newNode = spriteFactory.node(kind: armor) else { return }
        newNode.position = player.node.position
        newNode.zPosition = player.node.zPosition
        player.node.removeFromParent()
        worldNode.addChild(newNode)
        player.node = newNode
        spriteFactory.animate(newNode, kind: armor, animation: "idle_down")
    }

    private func damagePlayer(_ amount: Int) {
        player.hitPoints = max(0, player.hitPoints - amount)
        audio.play("hurt")
        updateHealthLabel()
        if player.hitPoints == 0 {
            player.hitPoints = player.maxHitPoints
            let checkpoint = map.checkpoints.first { $0.id == save.checkpointID } ?? map.checkpoints[0]
            player.node.position = map.worldPoint(x: checkpoint.x + checkpoint.w / 2,
                                                  y: checkpoint.y + checkpoint.h / 2,
                                                  tileSize: tileSize)
            audio.play("revive")
            showMessage("You were revived at the last checkpoint.")
        }
        save.hitPoints = player.hitPoints
        saveStore.save(save)
    }

    private func updateCheckpoint() {
        let grid = map.gridPosition(at: player.node.position, tileSize: tileSize)
        guard let checkpoint = map.checkpoints.first(where: {
            grid.x >= $0.x && grid.x < $0.x + $0.w && grid.y >= $0.y && grid.y < $0.y + $0.h
        }), checkpoint.id != lastCheckpointID else { return }
        lastCheckpointID = checkpoint.id
        save.checkpointID = checkpoint.id
        save.hitPoints = player.hitPoints
        saveStore.save(save)
        showMessage("Checkpoint saved to iCloud.")
    }

    private func updateHealthLabel() {
        healthLabel.text = "♥ \(player.hitPoints)/\(player.maxHitPoints)   ⚔ \(save.weapon)"
    }

    private func showMessage(_ text: String) {
        messageLabel.text = text
        messageLabel.removeAllActions()
        messageLabel.alpha = 1
        messageLabel.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.4)]))
    }

    private func showFatalError(_ message: String) {
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = message
        label.fontSize = 18
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = max(200, size.width - 80)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
