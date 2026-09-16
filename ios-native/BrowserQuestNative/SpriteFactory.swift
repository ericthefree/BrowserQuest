import SpriteKit

struct SpriteAnimation: Decodable {
    let length: Int
    let row: Int
}

struct SpriteSpec: Decodable {
    let id: String
    let width: Int
    let height: Int
    let animations: [String: SpriteAnimation]
}

final class SpriteFactory {
    private var specs: [String: SpriteSpec] = [:]
    private var sheets: [String: SKTexture] = [:]

    func node(kind: String, scale: CGFloat = 2) -> SKSpriteNode? {
        guard let spec = loadSpec(kind) else {
            return nil
        }
        let idle = spec.animations["idle_down"] == nil ? "idle" : "idle_down"
        guard let texture = frames(kind: kind, animation: idle).first else { return nil }
        let node = SKSpriteNode(texture: texture, size: CGSize(width: CGFloat(spec.width) * scale,
                                                               height: CGFloat(spec.height) * scale))
        node.texture?.filteringMode = .nearest
        node.name = "entity"
        return node
    }

    func animate(_ node: SKSpriteNode, kind: String, animation: String, flipped: Bool = false) {
        let textures = frames(kind: kind, animation: animation)
        guard !textures.isEmpty else { return }
        node.xScale = flipped ? -abs(node.xScale) : abs(node.xScale)
        if node.action(forKey: "animation") == nil || node.userData?["animation"] as? String != animation {
            node.removeAction(forKey: "animation")
            node.userData = node.userData ?? NSMutableDictionary()
            node.userData?["animation"] = animation
            node.run(.repeatForever(.animate(with: textures, timePerFrame: 0.11)), withKey: "animation")
        }
    }

    private func loadSpec(_ kind: String) -> SpriteSpec? {
        if let spec = specs[kind] { return spec }
        guard let url = Bundle.main.url(forResource: kind, withExtension: "json", subdirectory: "client/sprites"),
              let data = try? Data(contentsOf: url),
              let spec = try? JSONDecoder().decode(SpriteSpec.self, from: data) else { return nil }
        specs[kind] = spec
        return spec
    }

    private func frames(kind: String, animation: String) -> [SKTexture] {
        guard let spec = loadSpec(kind), let info = spec.animations[animation] else { return [] }
        let sheet = sheets[kind] ?? SKTexture(imageNamed: "client/img/1/\(spec.id).png")
        sheets[kind] = sheet
        sheet.filteringMode = .nearest
        let columns = max(1, Int(sheet.size().width) / spec.width)
        let rows = max(1, Int(sheet.size().height) / spec.height)
        return (0..<info.length).map { frame in
            let texture = SKTexture(
                rect: CGRect(x: CGFloat(frame) / CGFloat(columns),
                             y: 1 - CGFloat(info.row + 1) / CGFloat(rows),
                             width: 1 / CGFloat(columns),
                             height: 1 / CGFloat(rows)),
                in: sheet
            )
            texture.filteringMode = .nearest
            return texture
        }
    }
}
