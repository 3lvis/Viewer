import UIKit

extension UIViewController {
    func applicationWindow() -> UIWindow {
        return (UIApplication.sharedApplication().delegate?.window?!)!
    }
}