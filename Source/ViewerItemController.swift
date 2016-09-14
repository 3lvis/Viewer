import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(_ viewerItemController: ViewerItemController, completion: (() -> Void)?)
}

protocol ViewerItemControllerDataSource: class {
    func overlayIsHidden() -> Bool
}

class ViewerItemController: UIViewController {
    fileprivate static let FooterViewHeight = CGFloat(50.0)

    weak var controllerDelegate: ViewerItemControllerDelegate?
    weak var controllerDataSource: ViewerItemControllerDataSource?

    var indexPath: IndexPath?

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.clear
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.flashScrollIndicators()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = self.maxZoomScale()
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return scrollView
    }()

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.clear
        view.contentMode = .scaleAspectFit
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isUserInteractionEnabled = true

        return view
    }()

    lazy var movieContainer: MovieContainer = {
        let view = MovieContainer()
        view.viewDelegate = self

        return view
    }()

    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "play")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.playAction), for: .touchUpInside)

        return button
    }()

    lazy var repeatButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "repeat")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.repeatAction), for: .touchUpInside)

        return button
    }()

    lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "pause")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewerItemController.pauseAction), for: .touchUpInside)

        return button
    }()

    lazy var videoProgressView: VideoProgressView = {
        let progressView = VideoProgressView(frame: CGRect.zero)
        progressView.alpha = 0

        return progressView
    }()

    var changed = false
    var viewerItem: ViewerItem? {
        willSet {
            if self.viewerItem?.id != newValue?.id {
                self.changed = true
            }
        }

        didSet {
            guard let viewerItem = self.viewerItem else { return }

            if self.changed {
                self.movieContainer.image = viewerItem.placeholder
                self.imageView.image = viewerItem.placeholder
                self.movieContainer.frame = viewerItem.placeholder.centeredFrame()

                self.changed = false
            }
        }
    }

    func maxZoomScale() -> CGFloat {
        guard let image = self.imageView.image else { return 1 }

        var widthFactor = CGFloat(1.0)
        var heightFactor = CGFloat(1.0)
        if image.size.width > self.view.bounds.width {
            widthFactor = image.size.width / self.view.bounds.width
        }
        if image.size.height > self.view.bounds.height {
            heightFactor = image.size.height / self.view.bounds.height
        }

        return max(widthFactor, heightFactor)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.backgroundColor = UIColor.black

        self.scrollView.addSubview(self.imageView)

        self.view.addSubview(self.scrollView)
        self.view.addSubview(self.movieContainer)

        self.view.addSubview(self.playButton)
        self.view.addSubview(self.repeatButton)
        self.view.addSubview(self.pauseButton)
        self.view.addSubview(self.videoProgressView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewerItemController.tapAction))
        self.view.addGestureRecognizer(tapRecognizer)
    }

    func tapAction() {
        if self.movieContainer.isPlaying() {
            UIView.animate(withDuration: 0.3, animations: {
                self.pauseButton.alpha = self.pauseButton.alpha == 0 ? 1 : 0
                self.videoProgressView.alpha = self.videoProgressView.alpha == 0 ? 1 : 0
            }) 
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

        self.videoProgressView.frame = CGRect(x: 0, y: (self.view.frame.height - ViewerItemController.FooterViewHeight - VideoProgressView.Height), width: self.view.frame.width, height: VideoProgressView.Height)
    }

    func willDismiss() {
        guard let viewerItem = self.viewerItem else { return }

        if viewerItem.type == .Video {
            self.movieContainer.stopPlayerAndRemoveObserverIfNecessary()
            self.movieContainer.stop()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }

    func didFocused() {
        guard let viewerItem = self.viewerItem else { return }

        if viewerItem.type == .Video {
            self.movieContainer.start(viewerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(ViewerItemController.movieFinishedPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        } else {
            viewerItem.media({ image, error in
                if let image = image {
                    self.imageView.image = image
                    self.scrollView.maximumZoomScale = self.maxZoomScale()
                }
            })
        }
    }

    func movieFinishedPlaying() {
        self.repeatButton.alpha = 1
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
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
        self.videoProgressView.alpha = 0
        self.playIfNeeded()
    }

    func repeatAction() {
        self.repeatButton.alpha = 0

        if let overlayIsHidden = self.controllerDataSource?.overlayIsHidden() , !overlayIsHidden {
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
    func dimControls(_ alpha: CGFloat) {
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

extension ViewerItemController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if self.viewerItem?.type == .Image {
            return self.imageView
        } else {
            return nil
        }
    }
}

extension ViewerItemController: MovieContainerDelegate {
    func movieContainerDidStartedPlayingMovie(_ movieContainer: MovieContainer) {
        self.playIfNeeded()
    }

    func movieContainer(_ movieContainder: MovieContainer, didRequestToUpdateProgressBar duration: Double, currentTime: Double) {
       self.videoProgressView.currentTime = currentTime
       self.videoProgressView.duration = duration
    }
}
