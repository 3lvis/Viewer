import UIKit
import AVFoundation
import AVKit

protocol MovieContainerDelegate: class {
    func movieContainerDidStartedPlayingMovie(movieContainer: MovieContainer)
}

class MovieContainer: UIView {
    weak var viewDelegate: MovieContainerDelegate?

    lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        return playerLayer
    }()

    var image: UIImage?

    lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        view.autoresizingMask = [.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]

        return view
    }()

    lazy var playButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "play")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0
        button.addTarget(self, action: #selector(MovieContainer.playAction), forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var repeatButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "repeat")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0

        return button
    }()

    lazy var pauseButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "pause")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0
        button.addTarget(self, action: #selector(MovieContainer.pauseAction), forControlEvents: .TouchUpInside)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.addSublayer(self.playerLayer)
        self.addSubview(self.playButton)
        self.addSubview(self.repeatButton)
        self.addSubview(self.pauseButton)
        self.addSubview(self.loadingIndicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var shouldRegisterForNotifications = true
    var player: AVPlayer?

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = self.image else { return }
        self.frame = image.centeredFrame()

        var playerLayerFrame = image.centeredFrame()
        playerLayerFrame.origin.x = 0
        playerLayerFrame.origin.y = 0
        self.playerLayer.frame = playerLayerFrame

        let loadingHeight = self.loadingIndicator.frame.size.height
        let loadingWidth = self.loadingIndicator.frame.size.width
        self.loadingIndicator.frame = CGRect(x: (self.frame.size.width - loadingWidth) / 2, y: (self.frame.size.height - loadingHeight) / 2, width: loadingWidth, height: loadingHeight)

        let buttonImage = UIImage(named: "play")!
        let buttonHeight = buttonImage.size.height
        let buttonWidth = buttonImage.size.width
        self.playButton.frame = CGRect(x: (self.frame.size.width - buttonWidth) / 2, y: (self.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.repeatButton.frame = CGRect(x: (self.frame.size.width - buttonWidth) / 2, y: (self.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.pauseButton.frame = CGRect(x: (self.frame.size.width - buttonWidth) / 2, y: (self.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
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
        self.player?.pause()

        if self.shouldRegisterForNotifications == false {
            self.player?.removeObserver(self, forKeyPath: "status")
            self.shouldRegisterForNotifications = true
        }
    }

    func start() {
        if self.shouldRegisterForNotifications {
            self.loadingIndicator.startAnimating()

            self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)
            self.shouldRegisterForNotifications = false
        }
    }

    func pauseAction() {
        self.player?.pause()
        self.pauseButton.alpha = 0
        self.playButton.alpha = 1
    }

    func playAction() {
        self.player?.play()
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
        self.viewDelegate?.movieContainerDidStartedPlayingMovie(self)
    }
}
