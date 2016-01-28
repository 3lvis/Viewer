import UIKit
import AVFoundation
import AVKit

protocol PhotoViewerItemControllerDelegate: class {
    func photoViewerItemControllerDidTapItem(photoViewerItemController: PhotoViewerItemController, completion: (() -> Void)?)
}

class PhotoViewerItemController: UIViewController, ViewerItemControllable {
    weak var controllerDelegate: PhotoViewerItemControllerDelegate?

    var indexPath: NSIndexPath?

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.clearColor()
        view.contentMode = .ScaleAspectFit
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.userInteractionEnabled = true

        return view
    }()

    var changed = false
    var viewerItem: ViewerItem? {
        willSet {
            if self.viewerItem?.remoteID != newValue?.remoteID {
                self.changed = true
            }
        }

        didSet {
            guard let viewerItem = self.viewerItem else { return }

            if self.changed {
                self.imageView.image = viewerItem.placeholder
                viewerItem.media({ image in
                    if let image = image {
                        self.imageView.image = image
                    }
                })
                self.changed = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.imageView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    func tapAction() {
        self.controllerDelegate?.photoViewerItemControllerDidTapItem(self, completion: nil)
    }
}
