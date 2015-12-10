import UIKit

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    var applicationWindow: UIWindow {
        return (UIApplication.sharedApplication().delegate?.window?!)!
    }

    var viewerItem: ViewerItem? {
        didSet {
            if let photo = viewerItem as? Photo {
                self.label.text = String(photo.id ?? 0)
                self.imageView.image = photo.image
            }
        }
    }

    var index = 0

    lazy var label: UILabel = {
        let label = UILabel(frame: UIScreen.mainScreen().bounds)
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        label.font = UIFont.systemFontOfSize(80)
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return label
    }()

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.contentMode = .ScaleAspectFit
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.userInteractionEnabled = true

        return view
    }()

    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: "panAction:")
        gesture.delegate = self

        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.orangeColor()
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.label)
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)

        self.imageView.addGestureRecognizer(self.panGestureRecognizer)
    }

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self)
    }

    var firstX = CGFloat(0)
    var firstY = CGFloat(0)
    var isDragging = false

    func panAction(gesture: UIPanGestureRecognizer) {
        let viewHeight = self.view.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translationInView(self.view)

        if gesture.state == .Began {
            firstX = self.view.center.x
            firstY = self.view.center.y
            isDragging = true
            setNeedsStatusBarAppearanceUpdate()
        }

        translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
        let alpha = ((translatedPoint.y - viewHalfHeight) / viewHalfHeight)
        view.center = translatedPoint

        print("translatedPoint: \(translatedPoint)")
        print("viewHalfHeight: \(viewHalfHeight)")
        print("alpha: \(alpha)")

        if gesture.state == .Ended {
            if view.center.x > viewHalfHeight + 40 || view.center.y < viewHalfHeight - 40 {
                print("dismiss")
            }
        }

        print(" ")
    }
}

extension ViewerItemController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGestureRecognizer {
            let velocity = self.panGestureRecognizer.velocityInView(panGestureRecognizer.view!)
            let allowOnlyVerticalScrolls = fabs(velocity.y) > fabs(velocity.x)

            return allowOnlyVerticalScrolls
        }

        return true
    }
}
