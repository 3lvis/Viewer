import UIKit
import AVFoundation
import AVKit

#if os(iOS)
    import Photos
#endif

protocol VideoViewDelegate: class {
    func videoViewDidStartPlaying(_ videoView: VideoView)
    func videoView(_ videoView: VideoView, didRequestToUpdateProgressBar duration: Double, currentTime: Double)
    func videoViewDidFinishPlaying(_ videoView: VideoView, error: NSError?)
}

class VideoView: UIView {
    weak var delegate: VideoViewDelegate?

    private lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        return playerLayer
    }()

    var image: UIImage?

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]

        return view
    }()

    private lazy var loadingIndicatorBackground: UIImageView = {
        let view = UIImageView(image: UIImage(named: "dark-circle")!)
        view.alpha = 0

        return view
    }()

    private var shouldRegisterForStatusNotifications = true
    private var shouldRegisterForPlayerItemNotifications = true

    var slowMotionTimeObserver: Any?

    var playbackProgressTimeObserver: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        self.isUserInteractionEnabled = false
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }

        if let error = playerItem.error {
            self.stopPlayerAndRemoveObserverIfNecessary()
            self.cleanUpObservers()
            self.delegate?.videoViewDidFinishPlaying(self, error: error as NSError?)
        } else {
            guard let player = self.playerLayer.player else { fatalError("Player not found") }

            if keyPath == "status" {
                if playerItem.status == .readyToPlay {
                    self.stopPlayerAndRemoveObserverIfNecessary()

                    if self.playerLayer.isHidden == false {
                        player.play()
                        self.delegate?.videoViewDidStartPlaying(self)
                    }

                    if let playbackProgressTimeObserver = self.playbackProgressTimeObserver {
                        player.removeTimeObserver(playbackProgressTimeObserver)
                        self.playbackProgressTimeObserver = nil
                    }

                    let interval = CMTime(seconds: 1/60, preferredTimescale: Int32(NSEC_PER_SEC))
                    self.playbackProgressTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) {
                        time in
                        self.loadingIndicator.stopAnimating()
                        self.loadingIndicatorBackground.alpha = 0

                        let duration = CMTimeGetSeconds(playerItem.asset.duration)
                        let currentTime = CMTimeGetSeconds(player.currentTime())

                        self.updateProgressBar(forDuration: duration, currentTime: currentTime)
                    }
                }
            }
        }
    }

    func stopPlayerAndRemoveObserverIfNecessary() {
        self.playerLayer.player?.pause()

        if self.shouldRegisterForStatusNotifications == false {
            self.shouldRegisterForStatusNotifications = true

            guard let player = self.playerLayer.player else { fatalError("No player item was found") }
            guard let currentItem = player.currentItem else { return }

            currentItem.removeObserver(self, forKeyPath: "status")
        }
    }

    func prepare(using viewable: Viewable, completion: @escaping (Void) -> Void) {
        self.addPlayer(using: viewable) {
            if self.shouldRegisterForStatusNotifications {
                self.shouldRegisterForStatusNotifications = false

                guard let player = self.playerLayer.player else { fatalError("No player item was found") }
                guard let currentItem = player.currentItem else { return }

                currentItem.addObserver(self, forKeyPath: "status", options: [], context: nil)
            }

            if self.shouldRegisterForPlayerItemNotifications {
                self.shouldRegisterForPlayerItemNotifications = false

                NotificationCenter.default.addObserver(self, selector: #selector(self.videoFinishedPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

                NotificationCenter.default.addObserver(self, selector: #selector(self.itemPlaybackStalled), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
            }

            completion()
        }
    }

    func addPlayer(using viewable: Viewable, completion: @escaping (Void) -> Void) {
        if let assetID = viewable.assetID {
            #if os(iOS)
                let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                guard let asset = result.firstObject else { fatalError("Couldn't get asset for id: \(assetID)") }
                let requestOptions = PHVideoRequestOptions()
                requestOptions.isNetworkAccessAllowed = true
                requestOptions.version = .original
                requestOptions.deliveryMode = .fastFormat
                PHImageManager.default().requestPlayerItem(forVideo: asset, options: requestOptions) { playerItem, info in
                    guard let playerItem = playerItem else { fatalError("Player item was nil: \(info)") }

                    if let player = self.playerLayer.player {
                        player.replaceCurrentItem(with: playerItem)
                    } else {
                        let player = AVPlayer(playerItem: playerItem)
                        player.rate = Float(playerItem.preferredPeakBitRate)
                        self.playerLayer.player = player
                        self.playerLayer.isHidden = true

                        if let slowMotionTimeObserver = self.slowMotionTimeObserver {
                            player.removeTimeObserver(slowMotionTimeObserver)
                            self.slowMotionTimeObserver = nil
                        }

                        if asset.mediaSubtypes == .videoHighFrameRate {
                            let interval = CMTime(seconds: 1.0, preferredTimescale: Int32(NSEC_PER_SEC))
                            self.slowMotionTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
                                let currentTime = CMTimeGetSeconds(player.currentTime())
                                if currentTime >= 2 {
                                    if player.rate != 0.000001 {
                                        player.rate = 0.000001
                                    }
                                } else if player.rate != 1.0 {
                                    player.rate = 1.0
                                }
                            }
                        }
                    }

                    DispatchQueue.main.async {
                        completion()
                    }
                }
            #endif
        } else if let url = viewable.url {
            let streamingURL = URL(string: url)!

            if let player = self.playerLayer.player {
                // This will be triggered in the main queue because loading it from the
                // background doesn't work.
                player.replaceCurrentItem(with: AVPlayerItem(url: streamingURL))
                self.playerLayer.isHidden = true

                DispatchQueue.main.async {
                    completion()
                }
            } else {
                DispatchQueue.global(qos: .background).async {
                    self.playerLayer.player = AVPlayer(url: streamingURL)
                    self.playerLayer.isHidden = true

                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }

    func `repeat`() {
        self.playerLayer.player?.seek(to: kCMTimeZero)
        self.playerLayer.player?.play()
    }

    func cleanUpObservers() {
        if let slowMotionTimeObserver = self.slowMotionTimeObserver {
            self.playerLayer.player?.removeTimeObserver(slowMotionTimeObserver)
            self.slowMotionTimeObserver = nil
        }

        if let playbackProgressTimeObserver = self.playbackProgressTimeObserver {
            self.playerLayer.player?.removeTimeObserver(playbackProgressTimeObserver)
            self.playbackProgressTimeObserver = nil
        }

        if self.shouldRegisterForPlayerItemNotifications == false {
            self.shouldRegisterForPlayerItemNotifications = true

            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)

            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }

    func stop() {
        self.cleanUpObservers()

        self.playerLayer.isHidden = true
        self.playerLayer.player?.pause()
        self.playerLayer.player?.seek(to: kCMTimeZero)
        self.playerLayer.player = nil
    }

    func play() {
        guard let player = self.playerLayer.player else { fatalError("No player item was found") }

        if player.status == .unknown {
            self.loadingIndicator.startAnimating()
            self.loadingIndicatorBackground.alpha = 1
        }

        self.playerLayer.player?.play()
        self.playerLayer.isHidden = false
    }

    func pause() {
        self.playerLayer.player?.pause()
    }

    func isPlaying() -> Bool {
        if let player = self.playerLayer.player {
            let isPlaying = player.rate != 0 && player.error == nil
            return isPlaying
        }

        return false
    }

    func updateProgressBar(forDuration duration: Double, currentTime: Double) {
        self.delegate?.videoView(self, didRequestToUpdateProgressBar: duration, currentTime: currentTime)
    }

    func itemPlaybackStalled() {
        // When the video is having troubles buffering it might trigger the "AVPlayerItemPlaybackStalled" notification
        // the ideal scenario here, is that we'll pause the video, display the loading indicator for a while,
        // then continue the play back.
        // The current workaround just pauses the video and tries to play again, this might cause a shuddering video playback,
        // is not perfect but does the job for now.
        if let player = self.playerLayer.player {
            player.pause()
            player.play()
        }
    }

    func videoFinishedPlaying() {
        self.delegate?.videoViewDidFinishPlaying(self, error: nil)
    }
}
