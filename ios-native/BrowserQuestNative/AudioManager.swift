import AVFoundation

final class AudioManager {
    private var players: [AVAudioPlayer] = []

    func play(_ name: String) {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "mp3",
            subdirectory: "client/audio/sounds"
        ), let player = try? AVAudioPlayer(contentsOf: url) else { return }
        players.removeAll { !$0.isPlaying }
        players.append(player)
        player.play()
    }
}
