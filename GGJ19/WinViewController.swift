import UIKit

final class WinViewController: UIViewController {
    @IBAction func close() {
        ViewController.always.play()
        ViewController.sharedInstance.nextLevel()
        dismiss(animated: true, completion: nil)
    }
}
