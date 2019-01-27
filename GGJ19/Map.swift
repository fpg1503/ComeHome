import Foundation
import AVFoundation
import UIKit

struct Point: Hashable {
    let x: Int
    let y: Int

    init?(x: Int, y: Int) {
        guard x >= 0 && y >= 0 else { return nil }
        self.x = x
        self.y = y
    }

    func distance(to otherPoint: Point) -> Double {
        let xDist = self.x - otherPoint.x
        let yDist = self.y - otherPoint.y
        return sqrt(Double((xDist * xDist) + (yDist * yDist)))
    }
}

struct Sound: Hashable {
    let name: String
}

struct AudioSource {
    let origin: Point
    let sound: Sound

    var player: AVAudioPlayer {
        guard let player = ViewController.audioSourcePlayers[sound] else {
            let url = URL(string: Bundle.main.path(forResource: sound.name, ofType: "aac")!)!
            let newPlayer = try! AVAudioPlayer(contentsOf: url)
            ViewController.audioSourcePlayers[sound] = newPlayer
            return newPlayer
        }
        return player
    }
}

struct Map {
    let height: UInt
    let width: UInt

    let warning: [Point]
    let path: [Point]
    let destination: Point
    let startPoint: Point

    func isValid(point: Point) -> Bool {
        return point.x < width &&
            point.y < height &&
            (warning.contains(point) ||
                path.contains(point) ||
                startPoint == point ||
                destination == point)
    }

    static func from(grid: Grid) -> Map {
        let string = grid.toString()

        var warnings: [Point] = []
        var path: [Point] = []
        var destination: Point!
        var startPoint: Point!

        let lines = string.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for (y, line) in lines.enumerated() {
            for (x, character) in line.enumerated() {
                let point = Point(x: x, y: y)!
                switch String(character) {
                case "X": warnings.append(point)
                case "L": path.append(point)
                case "S": startPoint = point
                case "G": destination = point
                default: continue
                }
            }
        }

        let width = UInt(lines[0].count)
        let height = UInt(lines.count)

        return Map(height: height,
                   width: width,
                   warning: warnings,
                   path: path,
                   destination: destination,
                   startPoint: startPoint)
    }

    var initialState: State {
        return State(map: self,
                     currentLocation: startPoint,
                     audioSources: [AudioSource(origin: destination, sound: Sound(name: "g_area"))])
    }
}

struct State {
    let map: Map
    let currentLocation: Point
    let audioSources: [AudioSource]
}

enum Direction {
    case up, down, left, right
}

func + (lhs: Point, rhs: Direction) -> Point? {
    switch rhs {
    case .up:
        return Point(x: lhs.x, y: lhs.y - 1)
    case .down:
        return Point(x: lhs.x, y: lhs.y + 1)
    case .left:
        return Point(x: lhs.x - 1, y: lhs.y)
    case .right:
        return Point(x: lhs.x + 1, y: lhs.y)
    }
}

func walk(direction: Direction, state: State) -> State {
    guard let newPoint = state.currentLocation + direction,
        state.map.isValid(point: newPoint) else {
            alert()
            //Back to home
            loopWarning(false)
            return State(map: state.map,
                         currentLocation: state.map.startPoint,
                         audioSources: state.audioSources)
    }

    if state.map.destination == newPoint { yes() }
    loopWarning(state.map.warning.contains(newPoint))
    return State(map: state.map,
                 currentLocation: newPoint,
                 audioSources: state.audioSources)
}

func pan(for state: State, audioSource: AudioSource) -> Float {
    let audioX = audioSource.origin.x
    let myX = state.currentLocation.x

    if myX == audioX {
        return 0
    } else if myX < audioX {
        // Left
        let maximumLeftDistance = audioX
        let myDistance = audioX - myX
        let myRelativeDistance = Float(myDistance) / Float(maximumLeftDistance)
        return myRelativeDistance
    } else {
        // Right
        let maximumRightDistance = Int(state.map.width) - audioX
        let myDistance = myX - audioX
        let myRelativeDistance = Float(myDistance) / Float(maximumRightDistance)
        return myRelativeDistance
    }
}

func volume(for state: State, audioSource: AudioSource) -> Float {
    let maxDistanceToListen: Float = 5
    let myDistance = audioSource.origin.distance(to: state.currentLocation)

    let relativeAudio = max(0, (maxDistanceToListen - Float(myDistance)) / maxDistanceToListen)

    return relativeAudio
}

func loopWarning(_ on: Bool) {
    if on {
        ViewController.warning.play(atTime: 0)
        ViewController.warning.setVolume(1, fadeDuration: 0.5)
    } else {
        ViewController.warning.setVolume(0, fadeDuration: 0.5)
    }
}

func alert() {
    let url = URL(string: Bundle.main.path(forResource: "t_area", ofType: "aac")!)!
    let player = try! AVAudioPlayer(contentsOf: url)
    ViewController.players.append(player)
    player.play()
}

func yes() {
    ViewController.always.stop()
    let alertController = UIAlertController(title: "You won", message: "You won the game", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Great!", style: .default, handler: { _ in
        let state = ViewController.sharedInstance.state
        ViewController.sharedInstance.state = State(map: state.map,
                                                    currentLocation: state.map.startPoint,
                                                    audioSources: state.audioSources)
        ViewController.always.play()
    }))
    ViewController.sharedInstance.present(alertController, animated: true, completion: nil)
}
