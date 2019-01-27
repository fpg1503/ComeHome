import UIKit

final class WinViewController: UIViewController {
    @IBAction func close() {
        ViewController.always.play()
        ViewController.always.setVolume(1, fadeDuration: 0.2)
        ViewController.sharedInstance.nextLevel()
        dismiss(animated: true, completion: nil)
    }
}
