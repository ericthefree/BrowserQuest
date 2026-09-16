import Foundation

struct NativeSave: Codable {
    var checkpointID = 1
    var hitPoints = 80
    var armor = "clotharmor"
    var weapon = "sword1"
}

final class SaveStore {
    private let key = "BrowserQuestNative.save.v1"
    private let cloud = NSUbiquitousKeyValueStore.default

    func load() -> NativeSave {
        cloud.synchronize()
        let data = cloud.data(forKey: key) ?? UserDefaults.standard.data(forKey: key)
        return data.flatMap { try? JSONDecoder().decode(NativeSave.self, from: $0) } ?? NativeSave()
    }

    func save(_ value: NativeSave) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        cloud.set(data, forKey: key)
        cloud.synchronize()
    }
}
