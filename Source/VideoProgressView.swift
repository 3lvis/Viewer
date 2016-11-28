import UIKit

class VideoProgressView: UIView {
    static let Height = CGFloat(55.0)
    private static let ProgressBarXMargin = CGFloat(65.0)
    private static let ProgressBarYMargin = CGFloat(23.0)
    private static let ProgressBarHeight = CGFloat(6.0)

    private static let TextLabelWidth = CGFloat(36.0)
    private static let TextLabelHeight = CGFloat(18.0)
    private static let TextLabelMargin = CGFloat(18.0)

    var duration = 0.0 {
        didSet {
            if self.duration != oldValue {
              self.durationTimeLabel.text = self.timeStringForSeconds(self.duration)
            }
        }
    }
    var progress = 0.0 {
        didSet {
            self.currentTimeLabel.text = self.timeStringForSeconds(self.progress)
            self.setFrameForProgressBar()
        }
    }

    var progressPercentage: Double {
        guard self.progress != 0.0 && self.duration != 0.0 else {
            return 0.0
        }

        return progress/duration
    }

    var widthForBar: CGFloat {
        return self.bounds.width - (2 * VideoProgressView.ProgressBarXMargin)
    }

    var widthForProgressBar: CGFloat {
        return widthForBar * CGFloat(progressPercentage)
    }

    lazy var maskBarForRoundedCorners: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = .clear
        maskView.layer.cornerRadius = ProgressBarHeight/2
        maskView.clipsToBounds = true
        maskView.layer.masksToBounds = true;

        return maskView
    }()


    lazy var backgroundBar: UIView = {
        let backgroundBar = UIView()
        backgroundBar.backgroundColor = .white
        backgroundBar.alpha = 0.2

        return backgroundBar
    }()

    lazy var progressBar: UIView = {
        let progressBar = UIView()
        progressBar.backgroundColor = .white

        return progressBar
    }()

    lazy var currentTimeLabel: UILabel = {
        let currentTimeLabel = UILabel()
        currentTimeLabel.font = UIFont(name: "DINNextLTPro-Regular", size: 14)
        currentTimeLabel.textColor = .white

        return currentTimeLabel
    }()

    lazy var durationTimeLabel: UILabel = {
        let durationTimeLabel = UILabel()
        durationTimeLabel.font = UIFont(name: "DINNextLTPro-Regular", size: 14)
        durationTimeLabel.textColor = .white

        return durationTimeLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.maskBarForRoundedCorners)
        self.maskBarForRoundedCorners.addSubview(self.backgroundBar)
        self.maskBarForRoundedCorners.addSubview(self.progressBar)

        self.addSubview(self.currentTimeLabel)
        self.addSubview(self.durationTimeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.maskBarForRoundedCorners.frame = CGRect(x: VideoProgressView.ProgressBarXMargin, y: VideoProgressView.ProgressBarYMargin, width: self.widthForBar, height: VideoProgressView.ProgressBarHeight)
        self.backgroundBar.frame = CGRect(x: 0, y: 0, width: self.widthForBar, height: VideoProgressView.ProgressBarHeight)
        self.setFrameForProgressBar()

        let xPosForCurrentTimeLabel = (VideoProgressView.ProgressBarXMargin - VideoProgressView.TextLabelWidth)/2
        self.currentTimeLabel.frame = CGRect(x: xPosForCurrentTimeLabel, y: VideoProgressView.TextLabelMargin, width: VideoProgressView.TextLabelWidth, height: VideoProgressView.TextLabelHeight)
        let xPosForDurationTimeLabel = self.bounds.width - VideoProgressView.TextLabelWidth - (VideoProgressView.ProgressBarXMargin - VideoProgressView.TextLabelWidth)/2
        self.durationTimeLabel.frame = CGRect(x: xPosForDurationTimeLabel, y: VideoProgressView.TextLabelMargin, width: VideoProgressView.TextLabelWidth, height: VideoProgressView.TextLabelHeight)
    }

    func setFrameForProgressBar() {
        self.progressBar.frame = CGRect(x: 0, y: 0, width: self.widthForProgressBar, height: VideoProgressView.ProgressBarHeight)
    }

    func timeStringForSeconds(_ secondValue: Double) -> String {
       let minutes = Int((secondValue.truncatingRemainder(dividingBy: 3600)) / 60)
       let seconds = Int((secondValue.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60))

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
