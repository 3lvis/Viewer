import UIKit
import AVFoundation
import AVKit

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

    lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        return playerLayer
    }()

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]

        return view
    }()

    lazy var movieContainer: UIView = {
        let view = UIView()
        view.userInteractionEnabled = false
        view.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.4)
        view.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]

        return view
    }()

    private var shouldRegisterForNotifications = true
    var player: AVPlayer? {
        didSet {
            if self.shouldRegisterForNotifications {
                self.movieContainer.layer.addSublayer(self.playerLayer)
                self.movieContainer.addSubview(self.loadingIndicator)

                var playerLayerFrame = self.movieContainer.frame
                playerLayerFrame.origin.x = 0
                playerLayerFrame.origin.y = 0
                self.playerLayer.frame = playerLayerFrame

                let loadingHeight = self.loadingIndicator.frame.size.height
                let loadingWidth = self.loadingIndicator.frame.size.width
                self.loadingIndicator.frame = CGRect(x: (self.movieContainer.frame.size.width - loadingWidth) / 2, y: (self.movieContainer.frame.size.height - loadingHeight) / 2, width: loadingWidth, height: loadingHeight)

                self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)
                self.shouldRegisterForNotifications = false
            }
        }
    }

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
                self.movieContainer.frame = viewerItem.placeholder.centeredFrame()

                if let url = viewerItem.url {
                    self.loadingIndicator.startAnimating()
                    let steamingURL = NSURL(string: url)!
                    self.player = AVPlayer(URL: steamingURL)
                    self.playerLayer.player = player
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

        self.stopPlayerAndRemoveObserverIfNecessary()
    }

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self, completion: nil)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = object as? AVPlayer else { return }

        if player.status == .ReadyToPlay {
            self.stopPlayerAndRemoveObserverIfNecessary()
            player.play()
        }
    }

    func willDismiss() {
        self.stopPlayerAndRemoveObserverIfNecessary()
        self.loadingIndicator.removeFromSuperview()
        self.playerLayer.removeFromSuperlayer()
    }

    func stopPlayerAndRemoveObserverIfNecessary() {
        if self.shouldRegisterForNotifications == false {
            self.loadingIndicator.stopAnimating()
            self.player?.pause()
            self.player?.removeObserver(self, forKeyPath: "status")
            self.shouldRegisterForNotifications = true
        }
    }
}
