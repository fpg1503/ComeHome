import AVFoundation
import UIKit

class ViewController: UIViewController {

    static var sharedInstance: ViewController!
    static var players: [AVAudioPlayer] = []
    static var audioSourcePlayers: [Sound: AVAudioPlayer] = [:]

    static var warning: AVAudioPlayer!
    static var always: AVAudioPlayer!

    var state = State(map: Map(height: 10,
                               width: 10,
                               warning: [Point(x: 2, y: 1)!,
                                         Point(x: 2, y: 2)!,
                                         Point(x: 2, y: 3)!,
                                         Point(x: 2, y: 4)!,
                                         Point(x: 3, y: 1)!,
                                         Point(x: 4, y: 1)!,
                                         Point(x: 5, y: 1)!,
                                         Point(x: 5, y: 3)!,
                                         Point(x: 6, y: 1)!,
                                         Point(x: 7, y: 1)!,
                                         Point(x: 8, y: 1)!,
                                         Point(x: 8, y: 1)!,
                                         Point(x: 8, y: 2)!,
                                         Point(x: 8, y: 3)!,
                                         Point(x: 8, y: 4)!,
                                         Point(x: 8, y: 5)!,
                                         Point(x: 1, y: 5)!,
                                         Point(x: 2, y: 6)!,
                                         Point(x: 4, y: 3)!,
                                         Point(x: 4, y: 4)!,
                                         Point(x: 4, y: 5)!,
                                         Point(x: 4, y: 6)!,
                                         Point(x: 4, y: 7)!,
                                         Point(x: 2, y: 7)!,
                                         Point(x: 6, y: 3)!,
                                         Point(x: 6, y: 4)!,
                                         Point(x: 6, y: 5)!,
                                         Point(x: 6, y: 6)!,
                                         Point(x: 6, y: 7)!,
                                         Point(x: 3, y: 8)!],
                               path: [Point(x: 3, y: 2)!,
                                      Point(x: 3, y: 3)!,
                                      Point(x: 3, y: 4)!,
                                      Point(x: 3, y: 5)!,
                                      Point(x: 3, y: 6)!,
                                      Point(x: 3, y: 7)!,
                                      Point(x: 4, y: 2)!,
                                      Point(x: 5, y: 2)!,
                                      Point(x: 6, y: 2)!,
                                      Point(x: 7, y: 2)!,
                                      Point(x: 7, y: 3)!,
                                      Point(x: 7, y: 4)!,
                                      Point(x: 7, y: 5)!],
                               destination: Point(x: 7, y: 6)!,
                               startPoint: Point(x: 2, y: 5)!),
                      currentLocation: Point(x: 2, y: 5)!,
                      audioSources: [AudioSource(origin: Point(x: 7, y: 6)!,
                                                      sound: Sound(name: "g_area"))]) {
        didSet {
            updateState()
        }
    }

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        for player in state.audioSources.map({ $0.player }) {
            player.play()
            player.numberOfLoops = -1
        }

        let url = URL(string: Bundle.main.path(forResource: "x_area", ofType: "aac")!)!
        ViewController.warning = try! AVAudioPlayer(contentsOf: url)
        ViewController.warning.numberOfLoops = -1
        ViewController.warning.volume = 0
        ViewController.warning.play()
        updateState()

        let alwaysUrl = URL(string: Bundle.main.path(forResource: "l_area", ofType: "aac")!)!
        ViewController.always = try! AVAudioPlayer(contentsOf: alwaysUrl)
        ViewController.always.numberOfLoops = -1
        ViewController.always.play()
        ViewController.sharedInstance = self


        let layout = AudioFriendlyLayout(rows: 3, columns: 3)
        let grid = Grid(layout: layout)

        let algo = RecursiveBacktracker()
        algo.applyTo(grid)

        let geometry = OrthoWallwiseGeometryGenerator(grid: grid,
                                                      scale: 30,
                                                      margin: 10)
        let canvas = MazeCanvas(geometry: geometry)
        print(grid.toString())

        let map = Map.from(grid: grid)

        state = map.initialState
        view.addSubview(canvas)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func walk(_ sender: UIButton) {
        let direction: Direction
        switch sender.tag {
        case 0: direction = .up
        case 1: direction = .down
        case 2: direction = .left
        default: direction = .right
        }

        doWalk(direction: direction, state: state)
    }

    func doWalk(direction: Direction, state: State) {
        self.state = GGJ19.walk(direction: direction, state: state)
    }

    @IBAction func slided(_ sender: UISlider) {
        updateState()
    }

    func updateState() {
        let x = state.currentLocation.x
        let y = state.currentLocation.y

        for audioSource in state.audioSources {
            let player = audioSource.player
            player.pan = pan(for: state, audioSource: audioSource)
            let volume = GGJ19.volume(for: state, audioSource: audioSource)
            player.volume = volume
            if let always = ViewController.always {
                let lVolume = max(0.2, 1 - player.volume)
                always.volume = lVolume
                print("L -- \(lVolume)")
            }
            print("P: \(player.pan), V: \(volume)")
        }

        // Heart Beat
        ////        let sliderValue = slider.value
        //        let distance = state.map.destination.distance(to: state.currentLocation)
        //        let normalizedDistance = distance / Point(x: 0, y: 0)!.distance(to: state.map.destination)
        //        let sliderValue = Float(normalizedDistance)
        //        let maxHeart = 275
        //        let minHeart = 60
        //
        //        let relativeSlider = (sliderValue * Float(maxHeart - minHeart)) + Float(minHeart)
        //
        //        let soundSpeed: Float = 128
        //        let playbackSpeed = relativeSlider/soundSpeed
        //
        //        heart.rate = playbackSpeed

        //        label.text = "X: \(x)\nY: \(y)\nSlider: \(sliderValue)\nBPM: \(relativeSlider)"
        label.text = "X: \(x)\nY: \(y)"
    }

    override var canBecomeFirstResponder: Bool { return true }
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(up)),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(down)),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [], action: #selector(left)),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(right)),
        ]
    }

    @objc func up() {
        doWalk(direction: .up, state: state)
    }

    @objc func down() {
        doWalk(direction: .down, state: state)
    }

    @objc func left() {
        doWalk(direction: .left, state: state)
    }

    @objc func right() {
        doWalk(direction: .right, state: state)
    }
}

