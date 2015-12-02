import UIKit

class PhotoCell: UICollectionViewCell {
    static let Identifier = "PhotoCellIdentifier"

    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.redColor()
        self.addSubview(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String = "" {
        didSet {
            self.label.text = text
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
