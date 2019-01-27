import UIKit

final class LoseViewController: UIViewController {
    @IBAction func close() {
        ViewController.always.play()
        ViewController.sharedInstance.restartLevel()
        dismiss(animated: true, completion: nil)
    }
}
