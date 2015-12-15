import UIKit

class FooterView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.yellowColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}