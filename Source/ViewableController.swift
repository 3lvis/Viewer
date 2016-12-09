import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol ViewableControllerDelegate: class {
    func viewableControllerDidTapItem(_ viewableController: ViewableController)
    func viewableController(_ viewableController: ViewableController, didFailPlayingVideoWith error: NSError)
}

protocol ViewableControllerDataSource: class {
    func viewableControllerOverlayIsVisible(_ viewableController: ViewableController) -> Bool
    func viewableControllerIsFocused(_ viewableController: ViewableController) -> Bool
    func viewableControllerShouldAutoplayVideo(_ viewableController: ViewableController) -> Bool
}

class ViewableController: UIViewController {
    private static let FooterViewHeight = CGFloat(50.0)

    weak var delegate: ViewableControllerDelegate?
    weak var dataSource: ViewableControllerDataSource?

    lazy var zoomingScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.clipsToBounds = true

        return scrollView
    }()

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isUserInteractionEnabled = true

        return view
    }()

    lazy var videoView: VideoView = {
        let view = VideoView()
        view.delegate = self

        return view
    }()

    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "play")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewableController.playAction), for: .touchUpInside)

        return button
    }()

    lazy var repeatButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "repeat")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewableController.repeatAction), for: .touchUpInside)

        return button
    }()

    lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "pause")!
        button.setImage(image, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(ViewableController.pauseAction), for: .touchUpInside)

        return button
    }()

    lazy var videoProgressView: VideoProgressView = {
        let progressView = VideoProgressView(frame: .zero)
        progressView.alpha = 0

        return progressView
    }()

    var changed = false
    var viewable: Viewable?
    var indexPath: IndexPath?

    func update(with viewable: Viewable, at indexPath: IndexPath) {
        if self.indexPath?.description != indexPath.description {
            self.changed = true
        }

        if self.changed {
            self.indexPath = indexPath
            self.viewable = viewable
            self.videoView.image = viewable.placeholder
            self.imageView.image = viewable.placeholder
            self.videoView.frame = viewable.placeholder.centeredFrame()
            self.changed = false
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

        return max(2.0, max(widthFactor, heightFactor))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.backgroundColor = .black

        self.zoomingScrollView.addSubview(self.imageView)
        self.view.addSubview(self.zoomingScrollView)

        self.view.addSubview(self.videoView)

        self.view.addSubview(self.playButton)
        self.view.addSubview(self.repeatButton)
        self.view.addSubview(self.pauseButton)
        self.view.addSubview(self.videoProgressView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewableController.tapAction))
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)

        if viewable?.type == .image {
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewableController.doubleTapAction))
            doubleTapRecognizer.numberOfTapsRequired = 2
            self.zoomingScrollView.addGestureRecognizer(doubleTapRecognizer)

            tapRecognizer.require(toFail: doubleTapRecognizer)
        }
    }

    // In iOS 10 going into landscape provides a very strange animation. Basically you'll see the other
    // viewer items animating on top of the focused one. Horrible. This is a workaround that hides the
    // non-visible viewer items to avoid that. Also we hide the placeholder image view (zoomingScrollView)
    // because it was animating at a different timing than the video view and it looks bad.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let viewable = self.viewable else { return }

        let isFocused = self.dataSource?.viewableControllerIsFocused(self)
        if viewable.type == .video || isFocused == false {
            self.view.backgroundColor = .clear
            self.zoomingScrollView.isHidden = true
        }
        coordinator.animate(alongsideTransition: { context in

        }) { completionContext in
            if viewable.type == .video || isFocused == false {
                self.view.backgroundColor = .black
                self.zoomingScrollView.isHidden = false
            }
        }
    }

    func tapAction() {
        if self.videoView.isPlaying() {
            UIView.animate(withDuration: 0.3, animations: {
                self.pauseButton.alpha = self.pauseButton.alpha == 0 ? 1 : 0
                self.videoProgressView.alpha = self.videoProgressView.alpha == 0 ? 1 : 0
            })
        }

        self.delegate?.viewableControllerDidTapItem(self)
    }

    func doubleTapAction(recognizer: UITapGestureRecognizer) {
        let zoomScale = self.zoomingScrollView.zoomScale == 1 ? self.maxZoomScale() : 1

        let touchPoint = recognizer.location(in: self.imageView)

        let scrollViewSize = self.imageView.bounds.size

        let width = scrollViewSize.width / zoomScale
        let height = scrollViewSize.height / zoomScale
        let originX = touchPoint.x - (width / 2.0)
        let originY = touchPoint.y - (height / 2.0)

        let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)

        self.zoomingScrollView.zoom(to: rectToZoomTo, animated: true)

        self.imageView.frame = CGRect(x: 0, y: 0, width: self.imageView.frame.width, height: self.imageView.frame.height)
        self.zoomingScrollView.contentSize = self.imageView.frame.size
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let buttonImage = UIImage(named: "play")!
        let buttonHeight = buttonImage.size.height
        let buttonWidth = buttonImage.size.width
        self.playButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.repeatButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)
        self.pauseButton.frame = CGRect(x: (self.view.frame.size.width - buttonWidth) / 2, y: (self.view.frame.size.height - buttonHeight) / 2, width: buttonHeight, height: buttonHeight)

        self.videoProgressView.frame = CGRect(x: 0, y: (self.view.frame.height - ViewableController.FooterViewHeight - VideoProgressView.Height), width: self.view.frame.width, height: VideoProgressView.Height)
    }

    func willDismiss() {
        guard let viewable = self.viewable else { return }

        if viewable.type == .video {
            self.videoView.stop()
            self.resetButtonStates()
        }
    }

    func display() {
        guard let viewable = self.viewable else { return }

        switch viewable.type {
        case .image:
            viewable.media { image, error in
                if let image = image {
                    self.imageView.image = image
                    self.zoomingScrollView.minimumZoomScale = 1.0
                    self.zoomingScrollView.maximumZoomScale = self.maxZoomScale()
                    self.zoomingScrollView.contentSize = self.imageView.frame.size
                }
            }
        case .video:
            self.videoView.prepare(using: viewable) {
                let autoplayVideo = self.dataSource?.viewableControllerShouldAutoplayVideo(self) ?? false
                if autoplayVideo {
                    self.videoView.play()
                } else {
                    self.playButton.alpha = 1
                }
            }
        }
    }

    func resetButtonStates() {
        self.repeatButton.alpha = 0
        self.pauseButton.alpha = 0
        self.playButton.alpha = 1
        self.videoProgressView.alpha = 0
    }

    func pauseAction() {
        self.repeatButton.alpha = 0
        self.pauseButton.alpha = 0
        self.playButton.alpha = 1
        self.videoProgressView.alpha = 1

        self.videoView.pause()
    }

    func playAction() {
        self.repeatButton.alpha = 0
        self.pauseButton.alpha = 0
        self.playButton.alpha = 0
        self.videoProgressView.alpha = 0

        self.videoView.play()
        self.requestToHideOverlayIfNeeded()
    }

    func repeatAction() {
        self.repeatButton.alpha = 0

        let overlayIsVisible = self.dataSource?.viewableControllerOverlayIsVisible(self) ?? false
        if overlayIsVisible {
            self.pauseButton.alpha = 1
            self.videoProgressView.alpha = 1
        } else {
            self.videoProgressView.alpha = 0
        }

        self.videoView.repeat()
    }

    func requestToHideOverlayIfNeeded() {
        let overlayIsVisible = self.dataSource?.viewableControllerOverlayIsVisible(self) ?? false
        if overlayIsVisible {
            self.delegate?.viewableControllerDidTapItem(self)
        }
    }

    var shouldDimPause: Bool = false
    var shouldDimPlay: Bool = false
    var shouldDimVideoProgress: Bool = false

    func dimControls(_ alpha: CGFloat) {
        if self.pauseButton.alpha == 1.0 {
            self.shouldDimPause = true
        }

        if self.playButton.alpha == 1.0 {
            self.shouldDimPlay = true
        }

        if self.videoProgressView.alpha == 1.0 {
            self.shouldDimVideoProgress = true
        }

        if self.shouldDimPause {
            self.pauseButton.alpha = alpha
        }

        if self.shouldDimPlay {
            self.playButton.alpha = alpha
        }

        if self.shouldDimVideoProgress {
            self.videoProgressView.alpha = alpha
        }

        if alpha == 1.0 {
            self.shouldDimPause = false
            self.shouldDimPlay = false
            self.shouldDimVideoProgress = false
        }
    }
}

extension ViewableController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if self.viewable?.type == .image {
            return self.imageView
        } else {
            return nil
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = self.imageView.image else { return }

        let imageViewSize = self.imageView.frame.size
        let imageSize = image.size

        let realImageSize: CGSize
        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            realImageSize = CGSize(width: imageViewSize.width, height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImageSize = CGSize(width: imageViewSize.height / imageSize.height * imageSize.width, height: imageViewSize.height)
        }

        self.imageView.frame = CGRect(x: 0, y: 0, width: realImageSize.width, height: realImageSize.height)

        let scrollViewSize = scrollView.frame.size
        let horizontalInset = (scrollViewSize.width > realImageSize.width ? (scrollViewSize.width - realImageSize.width) / 2 : 0);
        let verticalInset = (scrollViewSize.height > realImageSize.height ? (scrollViewSize.height - realImageSize.height) / 2 : 0);

        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
}

extension ViewableController: VideoViewDelegate {

    func videoViewDidStartPlaying(_ videoView: VideoView) {
        self.requestToHideOverlayIfNeeded()
    }

    func videoView(_ videoView: VideoView, didChangeProgress progress: Double, duration: Double) {
        self.videoProgressView.progress = progress
        self.videoProgressView.duration = duration
    }

    func videoViewDidFinishPlaying(_ videoView: VideoView, error: NSError?) {
        if let error = error {
            self.delegate?.viewableController(self, didFailPlayingVideoWith: error)
        } else {
            self.repeatButton.alpha = 1
            self.pauseButton.alpha = 0
            self.playButton.alpha = 0
            self.videoProgressView.alpha = 0
        }
    }
}
