import UIKit

protocol HeaderViewDelegate: class {
    func headerView(headerView: HeaderView, didPressClearButton button: UIButton)
    func headerView(headerView: HeaderView, didPressMenuButton button: UIButton)
}

class HeaderView: UIView {
    weak var viewDelegate: HeaderViewDelegate?
    static let ButtonSize = CGFloat(50.0)
    static let TopMargin = CGFloat(15.0)

    lazy var clearButton: UIButton = {
        let image = UIImage(named: "clear")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(HeaderView.clearAction(_:)), forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var menuButton: UIButton = {
        let image = UIImage(named: "menu")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(HeaderView.menuAction(_:)), forControlEvents: .TouchUpInside)

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

        self.clearButton.frame = CGRect(x: 0, y: HeaderView.TopMargin, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)

        let x = UIScreen.mainScreen().bounds.size.width - HeaderView.ButtonSize
        self.menuButton.frame = CGRect(x: x, y: HeaderView.TopMargin, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)
    }

    func clearAction(button: UIButton) {
        viewDelegate?.headerView(self, didPressClearButton: button)
    }

    func menuAction(button: UIButton) {
        viewDelegate?.headerView(self, didPressMenuButton: button)
    }
}