import UIKit

class FooterView: UIView {
    static let FavoriteNotificationName  = "FavoriteNotificationName"
    static let DeleteNotificationName  = "DeleteNotificationName"
    static let ButtonSize = CGFloat(50.0)

    lazy var favoriteButton: UIButton = {
        let image = UIImage(named: "favorite")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(FooterView.favoriteAction(_:)), forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var deleteButton: UIButton = {
        let image = UIImage(named: "delete")!
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(FooterView.deleteAction(_:)), forControlEvents: .TouchUpInside)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.favoriteButton)
        self.addSubview(self.deleteButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let favoriteSizes = self.widthForElementAtIndex(0, totalElements: 2)
        self.favoriteButton.frame = CGRect(x: favoriteSizes.x, y: 0, width: favoriteSizes.width, height: FooterView.ButtonSize)

        let deleteSizes = self.widthForElementAtIndex(1, totalElements: 2)
        self.deleteButton.frame = CGRect(x: deleteSizes.x, y: 0, width: deleteSizes.width, height: FooterView.ButtonSize)
    }

    func widthForElementAtIndex(index: Int, totalElements: Int) -> (x: CGFloat, width: CGFloat) {
        let bounds = UIScreen.mainScreen().bounds
        let singleFrame = bounds.width / CGFloat(totalElements)
        return (singleFrame * CGFloat(index), singleFrame)
    }


    func favoriteAction(button: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(FooterView.FavoriteNotificationName, object: button)
    }

    func deleteAction(button: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(FooterView.DeleteNotificationName, object: button)
    }
}