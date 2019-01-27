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
                     audioSources: [AudioSource(origin: destination, sound: Sound(name: "goodboy"))], heading: .up)
    }
}

struct State {
    let map: Map
    let currentLocation: Point
    let audioSources: [AudioSource]
    let heading: Direction
}

enum Direction {
    case up, down, left, right

    var opposite: Direction {
        return self + .down
    }
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

func + (lhs: Direction, rhs: Direction) -> Direction {
    switch rhs {
    case .up: return lhs
    case .down:
        switch lhs {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    case .left:
        switch lhs {
        case .up: return .left
        case .down: return .right
        case .left: return .down
        case .right: return .up
        }
    case .right:
        switch lhs {
        case .up: return .right
        case .down: return .left
        case .left: return .up
        case .right: return .down
        }
    }
}

func walk(direction: Direction, state: State) -> State {
    // Walking is rotating and moving to the new forward

    // Set new heading
    let newHeading = direction == .down ? state.heading : state.heading + direction

    // Translate desired movement to north-heading
    // If left or right, just rotate heading!
    guard direction == .up || direction == .down else {
        AudioPlayer.sharedInstance.rotate()

        let newState = State(map: state.map,
                             currentLocation: state.currentLocation,
                             audioSources: state.audioSources,
                             heading: newHeading)

        loopWarning(newState, state.currentLocation, rotating: true)
        return newState
    }

    let translatedDirection = direction == .down ? newHeading.opposite : newHeading

    guard let newPoint = state.currentLocation + translatedDirection,
        state.map.isValid(point: newPoint) else {
            alert()
            //Back to home
            ViewController.warning.pause()
            return State(map: state.map,
                         currentLocation: state.map.startPoint,
                         audioSources: state.audioSources,
                         heading: .up)
    }

    if state.map.destination == newPoint { yes() }
    loopWarning(state, newPoint, rotating: false)

    AudioPlayer.sharedInstance.walk()
    return State(map: state.map,
                 currentLocation: newPoint,
                 audioSources: state.audioSources,
                 heading: newHeading)
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

func loopWarning(_ state: State, _ newPoint: Point, rotating: Bool) {
    // Count dogs!
    let upIsDog = Point(x: newPoint.x, y: newPoint.y - 1).map { !state.map.isValid(point: $0) } ?? true
    let downIsDog = Point(x: newPoint.x, y: newPoint.y + 1).map { !state.map.isValid(point: $0) } ?? true
    let leftIsDog = Point(x: newPoint.x - 1, y: newPoint.y).map { !state.map.isValid(point: $0) } ?? true
    let rightIsDog = Point(x: newPoint.x + 1, y: newPoint.y).map { !state.map.isValid(point: $0) } ?? true

    let dogCount = [upIsDog, downIsDog, leftIsDog, rightIsDog].map { $0 ? 1 : 0 }.reduce(0, +)

    let volume = dogCount == 0 ? 0 : 0.25 + (Float(dogCount) * 0.25)

    // Balance
    // Convert directions to player heading!
    let myLeftIsDog: Bool
    let myRightIsDog: Bool

    switch state.heading {
    case .up:
        myLeftIsDog = leftIsDog
        myRightIsDog = rightIsDog
    case .down:
        myLeftIsDog = rightIsDog
        myRightIsDog = leftIsDog
    case .left:
        myLeftIsDog = downIsDog
        myRightIsDog = upIsDog
    case .right:
        myLeftIsDog = upIsDog
        myRightIsDog = downIsDog
    }

    let pan: Float

    switch (myLeftIsDog, myRightIsDog) {
    case (false, false): pan = 0
    case (false, true): pan = 0.75
    case (true, false): pan = -0.75
    case (true, true): pan = 0
    }

    vibrate(dogCount, rotating)

    print("Dogs: \(dogCount) - Volume: \(volume) - Pan: \(pan) L: \(myLeftIsDog ? "T" : "F") R: \(myRightIsDog ? "T" : "F")")
    ViewController.warning.currentTime = 0
    ViewController.warning.play()
    ViewController.warning.pan = pan
    ViewController.warning.setVolume(volume, fadeDuration: 0.2)

    ViewController.warning2.currentTime = 0
    ViewController.warning2.play()
    ViewController.warning2.pan = pan
    ViewController.warning2.setVolume(volume, fadeDuration: 0.2)
}

func vibrate(_ dogs: Int, _ rotating: Bool) {
    guard dogs > 0, !rotating else { return }

    if (UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int ?? 0) >= 2 {
        switch dogs {
        case 1: AudioServicesPlaySystemSound(1519)
        case 2: AudioServicesPlaySystemSound(1520)
        case 3: AudioServicesPlaySystemSound(1521)
        default: break
        }
    } else {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

func alert() {
    ViewController.always.setVolume(0, fadeDuration: 3)
    let url = URL(string: Bundle.main.path(forResource: "death", ofType: "aac")!)!
    let player = try! AVAudioPlayer(contentsOf: url)
    ViewController.players.append(player)
    player.play()
    ViewController.sharedInstance.performSegue(withIdentifier: "lose", sender: nil)
}

func yes() {
    ViewController.always.setVolume(0, fadeDuration: 3)
    let url = URL(string: Bundle.main.path(forResource: "goodboy", ofType: "aac")!)!
    let player = try! AVAudioPlayer(contentsOf: url)
    ViewController.players.append(player)
    player.play()
    ViewController.sharedInstance.performSegue(withIdentifier: "win", sender: nil)
}
