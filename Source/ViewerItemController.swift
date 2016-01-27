import UIKit
import AVFoundation
import AVKit

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    private var shouldRegisterForNotifications = true
    var player: AVPlayer? {
        didSet {
            if self.shouldRegisterForNotifications {
                self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)
                self.shouldRegisterForNotifications = false
            }
        }
    }

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
        playerLayer.frame = self.view.frame
        self.view.layer.addSublayer(playerLayer)

        return playerLayer
    }()

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)

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

        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.imageView)
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        self.loadingIndicator.center = self.view.center
        self.view.addSubview(self.loadingIndicator)

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
