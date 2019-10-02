import UIKit

protocol HeaderViewDelegate: class {
    func headerView(_ headerView: HeaderView, didPressClearButton button: UIButton)
    func headerView(_ headerView: HeaderView, didPressMenuButton button: UIButton)
}

class HeaderView: UIView {
    weak var viewDelegate: HeaderViewDelegate?
    static let ButtonSize = CGFloat(50.0)
    static let TopMargin = CGFloat(15.0)

    lazy var clearButton: UIButton = {
        let image = UIImage.close
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(HeaderView.clearAction(button:)), for: .touchUpInside)

        return button
    }()

    lazy var menuButton: UIButton = {
        let image = UIImage(named: "menu", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(HeaderView.menuAction(button:)), for: .touchUpInside)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.clearButton)
        self.addSubview(self.menuButton)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.clearButton.frame = CGRect(x: 0, y: HeaderView.TopMargin, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)

        let x = UIScreen.main.bounds.size.width - HeaderView.ButtonSize
        self.menuButton.frame = CGRect(x: x, y: HeaderView.TopMargin, width: HeaderView.ButtonSize, height: HeaderView.ButtonSize)
    }

    @objc func clearAction(button: UIButton) {
        self.viewDelegate?.headerView(self, didPressClearButton: button)
    }

    @objc func menuAction(button: UIButton) {
        self.viewDelegate?.headerView(self, didPressMenuButton: button)
    }
}
