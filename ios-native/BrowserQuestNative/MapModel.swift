import CoreGraphics
import Foundation

struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

enum TileCell: Decodable {
    case single(Int)
    case layers([Int])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .single(value)
        } else {
            self = .layers(try container.decode([Int].self))
        }
    }

    var tileIDs: [Int] {
        switch self {
        case .single(let value): return value == 0 ? [] : [value]
        case .layers(let values): return values.filter { $0 != 0 }
        }
    }
}

struct AnimationSpec: Decodable {
    let l: Int
    let d: Int?
}

struct DoorSpec: Decodable {
    let x: Int
    let y: Int
    let tx: Int
    let ty: Int
    let to: String
    let p: Int
    let tcx: Int?
    let tcy: Int?
}

struct CheckpointSpec: Decodable {
    let id: Int
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

struct ClientMap: Decodable {
    let width: Int
    let height: Int
    let tilesize: Int
    let data: [TileCell]
    let collisions: [Int]
    let blocking: [Int]
    let high: [Int]
    let animated: [String: AnimationSpec]
    let doors: [DoorSpec]
    let checkpoints: [CheckpointSpec]

    private var blockedIndices: Set<Int> { Set(collisions).union(blocking) }

    func isBlocked(x: Int, y: Int) -> Bool {
        guard x >= 0, y >= 0, x < width, y < height else { return true }
        return blockedIndices.contains((y * width) + x)
    }

    func door(x: Int, y: Int) -> DoorSpec? {
        doors.first { $0.x == x && $0.y == y }
    }

    func worldPoint(x: Int, y: Int, tileSize: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(x) + 0.5) * tileSize,
                y: (CGFloat(height - y) - 0.5) * tileSize)
    }

    func gridPosition(at point: CGPoint, tileSize: CGFloat) -> GridPoint {
        GridPoint(x: Int(point.x / tileSize), y: height - 1 - Int(point.y / tileSize))
    }
}

struct RoamingArea: Decodable {
    let id: Int
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let type: String
    let nb: Int
}

struct StaticChest: Decodable {
    let x: Int
    let y: Int
    let i: [Int]
}

struct ServerMap: Decodable {
    let roamingAreas: [RoamingArea]
    let staticChests: [StaticChest]
    let staticEntities: [String: String]
}

enum GameDataError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let path): return "Missing bundled resource: \(path)"
        }
    }
}

enum GameDataLoader {
    static func load<T: Decodable>(_ type: T.Type, name: String, subdirectory: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory) else {
            throw GameDataError.missingResource("\(subdirectory)/\(name).json")
        }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}
