import UIKit

class HeaderView: UIView {
    static let ButtonSize = CGFloat(50.0)

    lazy var clearButton: UIButton = {
        let image = UIImage(named: "clear")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)

        return button
    }()

    lazy var menuButton: UIButton = {
        let image = UIImage(named: "menu")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.clearButton)
        self.addSubview(self.menuButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.clearButton.frame = CGRect(x: 0, y: 0, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)

        let x = UIScreen.mainScreen().bounds.size.width - HeaderView.ButtonSize
        self.menuButton.frame = CGRect(x: x, y: 0, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)
    }
}