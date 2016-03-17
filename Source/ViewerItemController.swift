import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

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

                if viewerItem.type == .Video {
                    self.movieContainer.loadingIndicator.startAnimating()

                    if let url = viewerItem.url {
                        let steamingURL = NSURL(string: url)!
                        self.movieContainer.player = AVPlayer(URL: steamingURL)
                        self.movieContainer.playerLayer.player = self.movieContainer.player
                        self.movieContainer.start()
                    } else if let remoteID = viewerItem.remoteID where viewerItem.local == true {
                        #if os(iOS)
                            let fechResult = PHAsset.fetchAssetsWithLocalIdentifiers([remoteID], options: nil)
                            if let object = fechResult.firstObject as? PHAsset {
                                PHImageManager.defaultManager().requestPlayerItemForVideo(object, options: nil, resultHandler: { playerItem, _ in
                                    if let playerItem = playerItem {
                                        dispatch_async(dispatch_get_main_queue(), {
                                            self.movieContainer.player = AVPlayer(playerItem: playerItem)
                                            self.movieContainer.playerLayer.player = self.movieContainer.player
                                            self.movieContainer.start()
                                        })
                                    }
                                })
                            }
                        #endif
                    }
                } else {
                    viewerItem.media({ image, error in
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
        self.controllerDelegate?.viewerItemControllerDidTapItem(self, completion: nil)
    }

    func willDismiss() {
        self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
        self.movieContainer.loadingIndicator.removeFromSuperview()
        self.movieContainer.playerLayer.removeFromSuperlayer()
    }

    func didCentered() {
        self.movieContainer.start()
        self.movieContainer.loadingIndicator.stopAnimating()
        self.movieContainer.player?.play()
    }
}
