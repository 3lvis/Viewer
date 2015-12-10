import UIKit

extension UIImage {
    func centeredFrame() -> CGRect {
        let screenBounds = UIScreen.mainScreen().bounds
        let widthScaleFactor = self.size.width / screenBounds.size.width
        let heightScaleFactor = self.size.height / screenBounds.size.height
        var centeredFrame: CGRect

        let shouldFitHorizontally = widthScaleFactor > heightScaleFactor
        if shouldFitHorizontally {
            let y = (screenBounds.size.height / 2) - ((self.size.height / widthScaleFactor) / 2)
            centeredFrame = CGRectMake(0, y, screenBounds.size.width, self.size.height / widthScaleFactor)
        } else {
            let x = (screenBounds.size.width / 2) - ((self.size.width / heightScaleFactor) / 2)
            centeredFrame = CGRectMake(x, 0, screenBounds.size.width - (2 * x), screenBounds.size.height)
        }

        return centeredFrame
    }
}