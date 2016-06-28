//
//  VideoProgressView.swift
//  Demo
//
//  Created by Marijn Schilling on 28/06/16.
//
//

import UIKit

class VideoProgressView: UIView {

    static let Height = CGFloat(55.0)
    private static let ProgressBarMargin = CGFloat(65.0)
    private static let ProgressBarHeight = CGFloat(6.0)

    var progress = 0.0 {
        didSet{
            self.layoutSubviews()
        }
    }

    var widthForBar : CGFloat {
        return self.bounds.width - 2 * VideoProgressView.ProgressBarMargin
    }

    var widthForProgressBar : CGFloat {
        return widthForBar * CGFloat(progress)
    }

    lazy var maskBarForRoundedCorners : UIView = {
        let maskView = UIView()
        maskView.backgroundColor = UIColor.clearColor()
        maskView.layer.cornerRadius = ProgressBarHeight/2
        maskView.clipsToBounds = true
        maskView.layer.masksToBounds = true;
        return maskView
    }()


    lazy var backgroundBar : UIView = {
        let backgroundBar = UIView()
        backgroundBar.backgroundColor = UIColor.whiteColor()
        backgroundBar.alpha = 0.2
        return backgroundBar
    }()

    lazy var progressBar : UIView = {
        let progressBar = UIView()
        progressBar.backgroundColor = UIColor.whiteColor()
        return progressBar
    }()

    override init(frame: CGRect) {
        
        super.init(frame: frame)

        self.addSubview(self.maskBarForRoundedCorners)
        self.maskBarForRoundedCorners.addSubview(self.backgroundBar)
        self.maskBarForRoundedCorners.addSubview(self.progressBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews(){
        super.layoutSubviews()

        self.maskBarForRoundedCorners.frame = CGRect(x: VideoProgressView.ProgressBarMargin, y: 22, width: self.widthForBar, height: VideoProgressView.ProgressBarHeight)
        self.backgroundBar.frame = CGRect(x: 0, y: 0, width: self.widthForBar, height: VideoProgressView.ProgressBarHeight)
        self.progressBar.frame = CGRect(x: 0, y: 0, width: self.widthForProgressBar, height: VideoProgressView.ProgressBarHeight)
    }

}
