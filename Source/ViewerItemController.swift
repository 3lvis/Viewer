import UIKit
import AVFoundation
import AVKit

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    var viewerItem: ViewerItem? {
        didSet {
            if let viewerItem = self.viewerItem {
                self.imageView.image = viewerItem.placeholder

                if let url = viewerItem.url {
                    self.loadingIndicator.startAnimating()
                    let steamingURL = NSURL(string: url)!
                    let player = AVPlayer(URL: steamingURL)
                    player.addObserver(self, forKeyPath: "status", options: [], context: nil)
                    self.playerLayer.player = player
                } else {
                    viewerItem.media({ image in
                        if let image = image {
                            self.imageView.image = image
                        }
                    })
                }
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
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(playerLayer)

        return playerLayer
    }()

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)

        return view
    }()

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

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self, completion: nil)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = object as? AVPlayer else { return }

        if player.status == .ReadyToPlay {
            self.loadingIndicator.stopAnimating()
            player.play()
        } else {
            print("BURNING BURNING")
        }
    }
}
