import UIKit

protocol FooterViewDelegate: class {
    func footerView(_ footerView: FooterView, didPressFavoriteButton button: UIButton)
    func footerView(_ footerView: FooterView, didPressDeleteButton button: UIButton)
}

class FooterView: UIView {
    weak var viewDelegate: FooterViewDelegate?
    static let ButtonSize = CGFloat(50.0)

    lazy var favoriteButton: UIButton = {
        let image = UIImage(named: "favorite", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)

        return button
    }()

    lazy var deleteButton: UIButton = {
        let image = UIImage(named: "delete", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.favoriteButton)
        self.addSubview(self.deleteButton)

        self.favoriteButton.addTarget(self, action: #selector(FooterView.favoriteAction(button:)), for: .touchUpInside)
        self.deleteButton.addTarget(self, action: #selector(FooterView.deleteAction(button:)), for: .touchUpInside)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let favoriteSizes = self.widthForElementAtIndex(index: 0, totalElements: 2)
        self.favoriteButton.frame = CGRect(x: favoriteSizes.x, y: 0, width: favoriteSizes.width, height: FooterView.ButtonSize)

        let deleteSizes = self.widthForElementAtIndex(index: 1, totalElements: 2)
        self.deleteButton.frame = CGRect(x: deleteSizes.x, y: 0, width: deleteSizes.width, height: FooterView.ButtonSize)
    }

    func widthForElementAtIndex(index: Int, totalElements: Int) -> (x: CGFloat, width: CGFloat) {
        let bounds = UIScreen.main.bounds
        let singleFrame = bounds.width / CGFloat(totalElements)

        return (singleFrame * CGFloat(index), singleFrame)
    }

    @objc func favoriteAction(button: UIButton) {
        self.viewDelegate?.footerView(self, didPressFavoriteButton: button)
    }

    @objc func deleteAction(button: UIButton) {
        self.viewDelegate?.footerView(self, didPressDeleteButton: button)
    }
}
