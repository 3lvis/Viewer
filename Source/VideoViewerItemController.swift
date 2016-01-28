import UIKit
import AVFoundation
import AVKit

protocol VideoViewerItemControllerDelegate: class {
    func videoViewerItemControllerDidTapItem(videoViewerItemController: VideoViewerItemController, completion: (() -> Void)?)
}

class VideoViewerItemController: UIViewController, ViewerItemControllable {
    weak var controllerDelegate: VideoViewerItemControllerDelegate?

    var indexPath: NSIndexPath?

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.clearColor()
        view.contentMode = .ScaleAspectFit
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.userInteractionEnabled = true

        return view
    }()

    lazy var movieContainer: MovieContainer = {
        let view = MovieContainer(frame: CGRectZero)

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
                self.movieContainer.image = viewerItem.placeholder
                self.imageView.image = viewerItem.placeholder
                self.movieContainer.frame = viewerItem.placeholder.centeredFrame()

                if let url = viewerItem.url {
                    self.movieContainer.loadingIndicator.startAnimating()
                    let steamingURL = NSURL(string: url)!
                    self.movieContainer.player = AVPlayer(URL: steamingURL)
                    self.movieContainer.playerLayer.player = self.movieContainer.player
                } else {
                    viewerItem.media({ image in
                        if let image = image {
                            self.imageView.image = image
                        }
                    })
                }
                self.changed = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.movieContainer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
    }

    func tapAction() {
        self.controllerDelegate?.videoViewerItemControllerDidTapItem(self, completion: nil)
    }

    func willDismiss() {
        self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
        self.movieContainer.loadingIndicator.removeFromSuperview()
        self.movieContainer.playerLayer.removeFromSuperlayer()
    }

    func didCentered() {
        // If it has already started then it will not play :(
        self.movieContainer.start()
    }
}
