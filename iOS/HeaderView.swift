import UIKit

class HeaderView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.redColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}