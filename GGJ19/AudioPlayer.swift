import AVFoundation

class AudioPlayer {
    static let sharedInstance = AudioPlayer()

    private func makePlayer(_ name: String) -> AVAudioPlayer {
        let url = URL(string: Bundle.main.path(forResource: name, ofType: "aac")!)!
        let newPlayer = try! AVAudioPlayer(contentsOf: url)

        return newPlayer
    }

    lazy var startPlayer: AVAudioPlayer = {
        return makePlayer("startbark")
    }()

    lazy var walkPlayer: AVAudioPlayer = {
        return makePlayer("footsteps")
    }()

    lazy var rotatePlayer: AVAudioPlayer = {
        return makePlayer("rotate")
    }()

    func start() {
        startPlayer.currentTime = 0
        startPlayer.play()
    }

    func walk() {
        walkPlayer.currentTime = 0
        walkPlayer.play()
    }

    func rotate() {
        rotatePlayer.currentTime = 0
        rotatePlayer.play()
    }
}
