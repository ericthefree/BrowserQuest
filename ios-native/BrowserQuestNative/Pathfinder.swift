import Foundation

enum Pathfinder {
    static func nextStep(from start: GridPoint, to goal: GridPoint, on map: ClientMap) -> GridPoint? {
        guard start != goal else { return goal }

        var queue = [start]
        var queueIndex = 0
        var previous: [GridPoint: GridPoint] = [:]
        var visited: Set<GridPoint> = [start]
        let directions = [GridPoint(x: 1, y: 0), GridPoint(x: -1, y: 0),
                          GridPoint(x: 0, y: 1), GridPoint(x: 0, y: -1)]

        while queueIndex < queue.count, visited.count < 512 {
            let current = queue[queueIndex]
            queueIndex += 1

            for direction in directions {
                let next = GridPoint(x: current.x + direction.x, y: current.y + direction.y)
                guard !visited.contains(next), !map.isBlocked(x: next.x, y: next.y) else { continue }
                visited.insert(next)
                previous[next] = current
                if next == goal {
                    return firstStep(from: start, to: goal, previous: previous)
                }
                queue.append(next)
            }
        }
        return nil
    }

    private static func firstStep(
        from start: GridPoint,
        to goal: GridPoint,
        previous: [GridPoint: GridPoint]
    ) -> GridPoint? {
        var step = goal
        while let parent = previous[step], parent != start {
            step = parent
        }
        return previous[step] == start ? step : nil
    }
}
