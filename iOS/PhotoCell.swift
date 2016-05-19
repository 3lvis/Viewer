import UIKit
import Photos

class PhotoCell: UICollectionViewCell {
    static let Identifier = "PhotoCellIdentifier"

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        self.backgroundColor = UIColor.blackColor()
        self.addSubview(self.imageView)
        self.addSubview(self.videoIndicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var videoIndicator: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "video-indicator")!
        view.hidden = true
        view.contentMode = .Center

        return view
    }()

    func display(photo: ViewerItem) {
        self.videoIndicator.hidden = photo.type == .Image

        if photo.local {
            if let asset = PHAsset.fetchAssetsWithLocalIdentifiers([photo.id], options: nil).firstObject {
                Photo.resolveAsset(asset as! PHAsset, size: .Small, completion: { image in
                    self.imageView.image = image
                })
            }
        } else {
            self.imageView.image = photo.placeholder
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.videoIndicator.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
