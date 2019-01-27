import AVFoundation
import UIKit

class ViewController: UIViewController {

    static var sharedInstance: ViewController!
    static var players: [AVAudioPlayer] = []
    static var audioSourcePlayers: [Sound: AVAudioPlayer] = [:]

    static var warning: AVAudioPlayer!
    static var warning2: AVAudioPlayer!

    static var always: AVAudioPlayer!

    var state: State! {
        didSet {
            updateState()
        }
    }

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var canvasHolder: UIView!
    @IBOutlet weak var gestureRecognizerView: UIView!

    private var upGestureRecognizer: UISwipeGestureRecognizer!
    private var downGestureRecognizer: UISwipeGestureRecognizer!
    private var leftGestureRecognizer: UISwipeGestureRecognizer!
    private var rightGestureRecognizer: UISwipeGestureRecognizer!

    private var debugDoubleTapGestureRecognizer: UITapGestureRecognizer!


    override func viewDidLoad() {
        super.viewDidLoad()

        addGestureRecognizers()
        generateAndSetRandomLevel()

        for player in state.audioSources.map({ $0.player }) {
            player.play()
            player.numberOfLoops = -1
        }

        //TODO: Fence, danger 1, 3
        let url = URL(string: Bundle.main.path(forResource: "danger2", ofType: "aac")!)!
        ViewController.warning = try! AVAudioPlayer(contentsOf: url)
        ViewController.warning.numberOfLoops = -1
        ViewController.warning.volume = 0
        ViewController.warning.play()

        let url2 = URL(string: Bundle.main.path(forResource: "danger999", ofType: "aac")!)!
        ViewController.warning2 = try! AVAudioPlayer(contentsOf: url2)
        ViewController.warning2.numberOfLoops = -1
        ViewController.warning2.volume = 0
        ViewController.warning2.play()
        updateState()

        //TODO: long whistle
        let alwaysUrl = URL(string: Bundle.main.path(forResource: "forest", ofType: "aac")!)!
        ViewController.always = try! AVAudioPlayer(contentsOf: alwaysUrl)
        ViewController.always.numberOfLoops = -1
        ViewController.always.play()
        ViewController.always.setVolume(1, fadeDuration: 0.2)
        ViewController.sharedInstance = self

        AudioPlayer.sharedInstance.start()
    }

    var difficulty = 0

    func generateAndSetRandomLevel(difficulty: Int = 0) {
        let layout = AudioFriendlyLayout(rows: 3 + difficulty, columns: 3)
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
        canvasHolder.subviews.forEach { $0.removeFromSuperview() }
        canvasHolder.addSubview(canvas)
    }

    func addGestureRecognizers() {
        let upG = UISwipeGestureRecognizer(target: self, action: #selector(up))
        upG.direction = .up
        upGestureRecognizer = upG

        let downG = UISwipeGestureRecognizer(target: self, action: #selector(down))
        downG.direction = .down
        downGestureRecognizer = downG

        let leftG = UISwipeGestureRecognizer(target: self, action: #selector(left))
        leftG.direction = .left
        leftGestureRecognizer = leftG

        let rightG = UISwipeGestureRecognizer(target: self, action: #selector(right))
        rightG.direction = .right
        rightGestureRecognizer = rightG

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDebug))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 2
        debugDoubleTapGestureRecognizer = tapGesture

        [upG, downG, leftG, rightG, tapGesture].forEach {
            gestureRecognizerView.addGestureRecognizer($0)
        }
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

    func nextLevel() {
        AudioPlayer.sharedInstance.start()
        difficulty += 1
        generateAndSetRandomLevel(difficulty: difficulty)
    }

    func restartLevel() {
        AudioPlayer.sharedInstance.start()
        state = state.map.initialState
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

        print("X: \(x) - Y: \(y) - New heading: \(String(describing: state.heading))")

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

    @objc func toggleDebug() {
        gestureRecognizerView.isHidden = !gestureRecognizerView.isHidden
    }
}

