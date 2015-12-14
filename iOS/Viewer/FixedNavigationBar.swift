import UIKit

class FixedNavigationBar: UINavigationBar {
    override func sizeThatFits(size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        if UIApplication.sharedApplication().statusBarHidden {
            size.height = 64
        }
        return size
    }
}