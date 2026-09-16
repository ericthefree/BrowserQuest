import SpriteKit

struct TileLayers {
    let ground: SKTileMapNode
    let detail: SKTileMapNode
    let overhead: SKTileMapNode
}

enum TileMapRenderer {
    static func makeLayers(map: ClientMap, tileSize: CGFloat) -> TileLayers {
        let sheet = SKTexture(imageNamed: "client/img/1/tilesheet.png")
        sheet.filteringMode = .nearest
        let columns = max(1, Int(sheet.size().width) / map.tilesize)
        let rows = max(1, Int(sheet.size().height) / map.tilesize)
        let usedIDs = Set(map.data.flatMap(\.tileIDs))
        var groups: [Int: SKTileGroup] = [:]

        func texture(_ id: Int) -> SKTexture {
            let index = id - 1
            let column = index % columns
            let row = index / columns
            let texture = SKTexture(
                rect: CGRect(x: CGFloat(column) / CGFloat(columns),
                             y: 1 - CGFloat(row + 1) / CGFloat(rows),
                             width: 1 / CGFloat(columns),
                             height: 1 / CGFloat(rows)),
                in: sheet
            )
            texture.filteringMode = .nearest
            return texture
        }

        for id in usedIDs {
            let definition: SKTileDefinition
            if let animation = map.animated[String(id)] {
                let textures = (id..<(id + animation.l)).map(texture)
                definition = SKTileDefinition(
                    textures: textures,
                    size: CGSize(width: tileSize, height: tileSize),
                    timePerFrame: TimeInterval(animation.d ?? 100) / 1000
                )
            } else {
                definition = SKTileDefinition(texture: texture(id), size: CGSize(width: tileSize, height: tileSize))
            }
            groups[id] = SKTileGroup(tileDefinition: definition)
        }

        let tileSet = SKTileSet(tileGroups: Array(groups.values))
        func layer(z: CGFloat) -> SKTileMapNode {
            let node = SKTileMapNode(
                tileSet: tileSet,
                columns: map.width,
                rows: map.height,
                tileSize: CGSize(width: tileSize, height: tileSize)
            )
            node.anchorPoint = .zero
            node.zPosition = z
            node.enableAutomapping = false
            return node
        }

        let ground = layer(z: 0)
        let detail = layer(z: 5)
        let overhead = layer(z: 100)
        let high = Set(map.high)

        for (index, cell) in map.data.enumerated() {
            let column = index % map.width
            let row = map.height - 1 - (index / map.width)
            var lowLayer = 0
            for id in cell.tileIDs {
                guard let group = groups[id] else { continue }
                if high.contains(id) {
                    overhead.setTileGroup(group, forColumn: column, row: row)
                } else if lowLayer == 0 {
                    ground.setTileGroup(group, forColumn: column, row: row)
                    lowLayer += 1
                } else {
                    detail.setTileGroup(group, forColumn: column, row: row)
                }
            }
        }

        return TileLayers(ground: ground, detail: detail, overhead: overhead)
    }
}
