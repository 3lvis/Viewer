import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?)
}

protocol ViewerItemControllerDataSource: class {
    func overlayIsHidden() -> Bool
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?
    weak var controllerDataSource: ViewerItemControllerDataSource?

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
        let view = MovieContainer()
        view.viewDelegate = self

        return view
    }()

    lazy var playButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "play")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.playAction), forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var repeatButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "repeat")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.repeatAction), forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var pauseButton: UIButton = {
        let button = UIButton(type: .Custom)
        let image = UIImage(named: "pause")!
        button.setImage(image, forState: .Normal)
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.pauseAction), forControlEvents: .TouchUpInside)

        return button
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
                    self.movieContainer.start(viewerItem)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewerItemController.movieFinishedPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
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

        self.view.addSubview(self.playButton)
        self.view.addSubview(self.repeatButton)
        self.view.addSubview(self.pauseButton)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewerItemController.tapAction))
        self.view.addGestureRecognizer(tapRecognizer)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
    }

    func tapAction() {
        if self.movieContainer.isPlaying() {
            UIView.animateWithDuration(0.3) {
                self.pauseButton.alpha = self.pauseButton.alpha == 0 ? 1 : 0
            }
        }

        self.controllerDelegate?.viewerItemControllerDidTapItem(self, completion: nil)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let buttonImage = UIImage(named: "play")!
        let buttonHeight = buttonImage.size.height
        let buttonWidth = buttonImage.size.width
        self.playButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.repeatButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.pauseButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
    }

    func willDismiss() {
        self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
        self.movieContainer.stop()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }

    func movieFinishedPlaying() {
        self.repeatButton.alpha = 1
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
    }

    func didCentered() {
        self.movieContainer.play()
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
        self.playIfNeeded()
    }

    func pauseAction() {
        self.movieContainer.pause()
        self.pauseButton.alpha = 0
        self.playButton.alpha = 1
    }

    func playAction() {
        self.movieContainer.play()
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
        self.playIfNeeded()
    }

    func repeatAction() {
        self.repeatButton.alpha = 0

        if let overlayIsHidden = self.controllerDataSource?.overlayIsHidden() where !overlayIsHidden {
            self.pauseButton.alpha = 1
        }

        self.movieContainer.stop()
        self.movieContainer.play()
    }

    func playIfNeeded() {
        let overlayIsHidden = self.controllerDataSource?.overlayIsHidden() ?? false
        if overlayIsHidden == false {
            self.controllerDelegate?.viewerItemControllerDidTapItem(self, completion: nil)
        }
    }

    var shouldDimPause: Bool = false
    var shouldDimPlay: Bool = false
    func dimControls(alpha: CGFloat) {
        if self.pauseButton.alpha == 1.0 {
            self.shouldDimPause = true
        }

        if self.playButton.alpha == 1.0 {
            self.shouldDimPlay = true
        }

        if self.shouldDimPause {
            self.pauseButton.alpha = alpha
        }

        if self.shouldDimPlay {
            self.playButton.alpha = alpha
        }

        if alpha == 1.0 {
            self.shouldDimPause = false
            self.shouldDimPlay = false
        }
    }
}

extension ViewerItemController: MovieContainerDelegate {
    func movieContainerDidStartedPlayingMovie(movieContainer: MovieContainer) {
        self.playIfNeeded()
    }
}