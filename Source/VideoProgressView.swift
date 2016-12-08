import UIKit

class VideoProgressView: UIView {
    static let Height = CGFloat(55.0)
    private static let progressBarYMargin = CGFloat(23.0)
    private static let progressBarHeight = CGFloat(6.0)

    private static let textLabelHeight = CGFloat(18.0)
    private static let textLabelMargin = CGFloat(18.0)

    var duration = 0.0 {
        didSet {
            if self.duration != oldValue {
                self.durationTimeLabel.text = self.duration.timeString()
                self.layoutSubviews()
            }
        }
    }
    var progress = 0.0 {
        didSet {
            self.currentTimeLabel.text = self.progress.timeString()
            self.layoutSubviews()
        }
    }

    var progressPercentage: Double {
        guard self.progress != 0.0 && self.duration != 0.0 else {
            return 0.0
        }

        return self.progress/self.duration
    }

    lazy var progressBarMask: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = .clear
        maskView.layer.cornerRadius = VideoProgressView.progressBarHeight/2
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
        let label = UILabel()
        label.font = UIFont(name: "DINNextLTPro-Regular", size: 14)
        label.textColor = .white
        label.textAlignment = .center

        return label
    }()

    lazy var durationTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DINNextLTPro-Regular", size: 14)
        label.textColor = .white
        label.textAlignment = .center

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.progressBarMask)
        self.progressBarMask.addSubview(self.backgroundBar)
        self.progressBarMask.addSubview(self.progressBar)

        self.addSubview(self.currentTimeLabel)
        self.addSubview(self.durationTimeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var currentTimeLabelFrame: CGRect {
            let width = self.currentTimeLabel.width() + VideoProgressView.textLabelMargin
            return CGRect(x: 0, y: VideoProgressView.textLabelMargin, width: width, height: VideoProgressView.textLabelHeight)
        }
        self.currentTimeLabel.frame = currentTimeLabelFrame

        var durationTimeLabelFrame: CGRect {
            let width = self.durationTimeLabel.width() + VideoProgressView.textLabelMargin
            let x = self.bounds.width - width
            return CGRect(x: x, y: VideoProgressView.textLabelMargin, width: width, height: VideoProgressView.textLabelHeight)
        }
        self.durationTimeLabel.frame = durationTimeLabelFrame

        var maskBarForRoundedCornersFrame: CGRect {
            let x = self.currentTimeLabel.frame.width
            let width = self.bounds.width - self.currentTimeLabel.frame.width - self.durationTimeLabel.frame.width
            return CGRect(x: x, y: VideoProgressView.progressBarYMargin, width: width, height: VideoProgressView.progressBarHeight)
        }
        self.progressBarMask.frame = maskBarForRoundedCornersFrame

        var backgroundBarFrame: CGRect {
            let width = self.progressBarMask.frame.width
            return CGRect(x: 0, y: 0, width: width, height: VideoProgressView.progressBarHeight)
        }
        self.backgroundBar.frame = backgroundBarFrame

        var progressBarFrame: CGRect {
            let width = self.progressBarMask.frame.width * CGFloat(self.progressPercentage)
            return CGRect(x: 0, y: 0, width: width, height: VideoProgressView.progressBarHeight)
        }
        self.progressBar.frame = progressBarFrame
    }
}

public extension UILabel {
    public func width() -> CGFloat {
        let rect = (self.attributedText ?? NSAttributedString()).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return rect.width
    }
}

extension Double {
    func timeString() -> String {
        let remaining = floor(self)
        let hours = Int(remaining / 3600)
        let minutes = Int(remaining / 60) - hours * 60
        let seconds = Int(remaining) - hours * 3600 - minutes * 60

        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        let secondsString = String(format: "%02d", seconds)

        if hours > 0 {
            let hoursString = formatter.string(from: NSNumber(value: hours))
            if let hoursString = hoursString {
                let minutesString = String(format: "%02d", minutes)
                return "\(hoursString):\(minutesString):\(secondsString)"
            }
        } else {
            if let minutesString = formatter.string(from: NSNumber(value: minutes)) {
                return "\(minutesString):\(secondsString)"
            }
        }

        return ""
    }
}
