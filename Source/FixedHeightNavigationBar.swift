import UIKit

class FixedHeightNavigationBar: UINavigationBar {
    override func sizeThatFits(size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if UIApplication.sharedApplication().statusBarHidden && UIInterfaceOrientationIsPortrait(orientation) {
            size.height = 64
        }
        return size
    }
}