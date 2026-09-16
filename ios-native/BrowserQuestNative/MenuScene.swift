import SpriteKit
import UIKit

final class MenuScene: SKScene {
    var onCreate: (() -> Void)?
    var onStart: (() -> Void)?
    var onDelete: (() -> Void)?

    private let saveStore = SaveStore()
    private let spriteFactory = SpriteFactory()

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 37 / 255, green: 34 / 255, blue: 27 / 255, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        rebuild()
    }

    private func rebuild() {
        removeAllChildren()
        let hasCharacter = saveStore.hasCharacter()
        let save = saveStore.load()

        let title = label("BROWSERQUEST", size: 42, y: size.height * 0.78)
        title.fontColor = UIColor(red: 252 / 255, green: 218 / 255, blue: 92 / 255, alpha: 1)
        addChild(title)

        let subtitle = label("NATIVE", size: 18, y: size.height * 0.70)
        subtitle.fontColor = .lightGray
        addChild(subtitle)

        if hasCharacter {
            if let node = spriteFactory.node(kind: save.armor, scale: 2.5) {
                node.position = CGPoint(x: size.width / 2, y: size.height * 0.53)
                addChild(node)
                spriteFactory.animate(node, kind: save.armor, animation: "idle_down")
            }
            let name = save.playerName?.isEmpty == false ? save.playerName! : "Adventurer"
            addChild(label(name, size: 24, y: size.height * 0.39))
            addButton(title: "START GAME", action: "start", y: size.height * 0.27, color: .systemGreen)
            addButton(title: "DELETE CHARACTER", action: "delete", y: size.height * 0.15, color: .systemRed)
        } else {
            addChild(label("Create a character to begin", size: 20, y: size.height * 0.50))
            addButton(title: "CREATE CHARACTER", action: "create", y: size.height * 0.32, color: .systemBlue)
        }
    }

    private func label(_ text: String, size fontSize: CGFloat, y: CGFloat) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: "Courier-Bold")
        node.text = text
        node.fontSize = fontSize
        node.verticalAlignmentMode = .center
        node.position = CGPoint(x: size.width / 2, y: y)
        return node
    }

    private func addButton(title: String, action: String, y: CGFloat, color: UIColor) {
        let width = min(size.width - 48, 360)
        let button = SKShapeNode(rectOf: CGSize(width: width, height: 58), cornerRadius: 8)
        button.name = action
        button.position = CGPoint(x: size.width / 2, y: y)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.65)
        button.lineWidth = 3
        button.zPosition = 10

        let text = SKLabelNode(fontNamed: "Courier-Bold")
        text.name = action
        text.text = title
        text.fontSize = 19
        text.verticalAlignmentMode = .center
        text.zPosition = 1
        button.addChild(text)
        addChild(button)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let action = nodes(at: point).compactMap(\.name).first
        switch action {
        case "create": onCreate?()
        case "start": onStart?()
        case "delete": onDelete?()
        default: break
        }
    }
}
