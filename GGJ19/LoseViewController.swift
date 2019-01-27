import UIKit

final class LoseViewController: UIViewController {
    @IBAction func close() {
        ViewController.always.play()
        ViewController.always.setVolume(1, fadeDuration: 0.2)
        ViewController.sharedInstance.restartLevel()
        dismiss(animated: true, completion: nil)
    }
}
