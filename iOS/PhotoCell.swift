import UIKit

class PhotoCell: UICollectionViewCell {
    static let Identifier = "PhotoCellIdentifier"

    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(40)
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return label
    }()

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        self.backgroundColor = UIColor.redColor()
        self.addSubview(self.imageView)
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

    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
