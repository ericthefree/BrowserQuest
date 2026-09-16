import SpriteKit

enum EntityRole {
    case player
    case mob
    case npc
    case item
    case chest
}

final class EntityModel {
    let id: String
    let kind: String
    let role: EntityRole
    var node: SKSpriteNode
    var hitPoints: Int
    var maxHitPoints: Int
    var attackPower: Int
    var lastAttackTime: TimeInterval = 0
    var lastPathTime: TimeInterval = 0
    var nextPathStep: GridPoint?

    init(id: String, kind: String, role: EntityRole, node: SKSpriteNode,
         hitPoints: Int = 1, attackPower: Int = 0) {
        self.id = id
        self.kind = kind
        self.role = role
        self.node = node
        self.hitPoints = hitPoints
        self.maxHitPoints = hitPoints
        self.attackPower = attackPower
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["entityID"] = id
    }
}

enum EntityCatalog {
    static let mobs: Set<String> = [
        "rat", "skeleton", "goblin", "ogre", "spectre", "crab", "bat", "wizard",
        "eye", "snake", "skeleton2", "boss", "deathknight"
    ]
    static let items: Set<String> = [
        "flask", "burger", "firepotion", "cake", "sword1", "sword2", "axe",
        "redsword", "bluesword", "goldensword", "morningstar", "clotharmor",
        "leatherarmor", "mailarmor", "platearmor", "redarmor", "goldenarmor"
    ]

    static func role(for kind: String) -> EntityRole {
        if mobs.contains(kind) { return .mob }
        if items.contains(kind) { return .item }
        if kind == "chest" { return .chest }
        return .npc
    }

    static func stats(for kind: String) -> (hp: Int, attack: Int) {
        switch kind {
        case "rat": return (25, 4)
        case "skeleton": return (110, 8)
        case "goblin": return (90, 7)
        case "ogre": return (200, 14)
        case "spectre": return (250, 18)
        case "crab": return (60, 6)
        case "bat": return (80, 6)
        case "wizard": return (100, 20)
        case "eye": return (200, 14)
        case "snake": return (150, 10)
        case "skeleton2": return (200, 14)
        case "boss": return (700, 30)
        case "deathknight": return (250, 18)
        default: return (1, 0)
        }
    }

    static func playerHitPoints(for armor: String) -> Int {
        let armors = ["clotharmor", "leatherarmor", "mailarmor", "platearmor", "redarmor", "goldenarmor"]
        let armorLevel = (armors.firstIndex(of: armor) ?? 0) + 1
        return 80 + ((armorLevel - 1) * 30)
    }
}
