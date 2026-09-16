import Foundation

struct NativeSave: Codable {
    var checkpointID = 1
    var hitPoints = 80
    var armor = "clotharmor"
    var weapon = "sword1"
    var playerName: String?
}

final class SaveStore {
    private let key = "BrowserQuestNative.save.v1"
    private let cloud = NSUbiquitousKeyValueStore.default

    func load() -> NativeSave {
        cloud.synchronize()
        let data = cloud.data(forKey: key) ?? UserDefaults.standard.data(forKey: key)
        return data.flatMap { try? JSONDecoder().decode(NativeSave.self, from: $0) } ?? NativeSave()
    }

    func hasCharacter() -> Bool {
        cloud.synchronize()
        return cloud.data(forKey: key) != nil || UserDefaults.standard.data(forKey: key) != nil
    }

    func createCharacter(named name: String) {
        var character = NativeSave()
        character.playerName = name
        save(character)
    }

    func save(_ value: NativeSave) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        cloud.set(data, forKey: key)
        cloud.synchronize()
    }

    func deleteCharacter() {
        UserDefaults.standard.removeObject(forKey: key)
        cloud.removeObject(forKey: key)
        cloud.synchronize()
    }
}
