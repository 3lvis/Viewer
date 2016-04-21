import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol MovieContainerDelegate: class {
    func movieContainerDidStartedPlayingMovie(movieContainer: MovieContainer)
}

class MovieContainer: UIView {
    weak var viewDelegate: MovieContainerDelegate?

    private lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        return playerLayer
    }()

    var image: UIImage?

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        view.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]

        return view
    }()

    private lazy var loadingIndicatorBackground: UIImageView = {
        let view = UIImageView(image: UIImage(named: "dark-circle")!)
        view.alpha = 0

        return view
    }()

    private var shouldRegisterForNotifications = true
    private var player: AVPlayer?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.userInteractionEnabled = false
        self.layer.addSublayer(self.playerLayer)
        self.addSubview(self.loadingIndicatorBackground)
        self.addSubview(self.loadingIndicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = self.image else { return }
        self.frame = image.centeredFrame()

        var playerLayerFrame = image.centeredFrame()
        playerLayerFrame.origin.x = 0
        playerLayerFrame.origin.y = 0
        self.playerLayer.frame = playerLayerFrame

        let loadingBackgroundHeight = self.loadingIndicatorBackground.frame.size.height
        let loadingBackgroundWidth = self.loadingIndicatorBackground.frame.size.width
        self.loadingIndicatorBackground.frame = CGRect(x: (self.frame.size.width - loadingBackgroundWidth) / 2, y: (self.frame.size.height - loadingBackgroundHeight) / 2, width: loadingBackgroundWidth, height: loadingBackgroundHeight)

        let loadingHeight = self.loadingIndicator.frame.size.height
        let loadingWidth = self.loadingIndicator.frame.size.width
        self.loadingIndicator.frame = CGRect(x: (self.frame.size.width - loadingWidth) / 2, y: (self.frame.size.height - loadingHeight) / 2, width: loadingWidth, height: loadingHeight)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = object as? AVPlayer else { return }

        if player.status == .ReadyToPlay {
            self.stopPlayerAndRemoveObserverIfNecessary()
            player.play()
            self.viewDelegate?.movieContainerDidStartedPlayingMovie(self)
        }
    }

    func stopPlayerAndRemoveObserverIfNecessary() {
        self.loadingIndicator.stopAnimating()
        self.loadingIndicatorBackground.alpha = 0
        self.player?.pause()

        if self.shouldRegisterForNotifications == false {
            self.player?.removeObserver(self, forKeyPath: "status")
            self.shouldRegisterForNotifications = true
        }
    }

    func start(viewerItem: ViewerItem) {
        if let url = viewerItem.url {
            let steamingURL = NSURL(string: url)!
            self.player = AVPlayer(URL: steamingURL)
            self.playerLayer.player = self.player
            self.start()
        } else if viewerItem.local == true {
            #if os(iOS)
                let result = PHAsset.fetchAssetsWithLocalIdentifiers([viewerItem.remoteID], options: nil)
                guard let object = result.firstObject as? PHAsset else { fatalError("Couldn't get asset for id: \(viewerItem.remoteID)") }
                let requestOptions = PHVideoRequestOptions()
                requestOptions.networkAccessAllowed = true
                requestOptions.version = .Original
                PHImageManager.defaultManager().requestPlayerItemForVideo(object, options: requestOptions, resultHandler: { playerItem, info in
                    guard let playerItem = playerItem else { fatalError("Player item was nil: \(info)") }
                    print(playerItem.tracks)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.player = AVPlayer(playerItem: playerItem)
                        self.player?.rate = Float(playerItem.preferredPeakBitRate)
                        self.playerLayer.player = self.player
                        self.start()
                    })
                })
            #endif
        }
    }

    func start() {
        self.playerLayer.hidden = false

        if self.shouldRegisterForNotifications {
            guard let player = self.player else { fatalError("No player item was found") }

            if player.status == .Unknown {
                self.loadingIndicator.startAnimating()
                self.loadingIndicatorBackground.alpha = 1
            }

            player.addObserver(self, forKeyPath: "status", options: [], context: nil)
            self.shouldRegisterForNotifications = false
        }
    }

    func stop() {
        self.playerLayer.hidden = true
        self.player?.pause()
        self.player?.seekToTime(kCMTimeZero)
        self.playerLayer.player = nil
    }

    func play() {
        self.player?.play()
        self.playerLayer.hidden = false
    }

    func pause() {
        self.player?.pause()
    }

    func isPlaying() -> Bool {
        if let player = self.player {
            let isPlaying = player.rate != 0 && player.error == nil
            return isPlaying
        }

        return false
    }
}
