import UIKit

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    var viewerItem: ViewerItem? {
        didSet {
            if let photo = viewerItem as? Photo {
                self.label.text = String(photo.id ?? 0)
                self.imageView.image = photo.image
            }
        }
    }

    lazy var label: UILabel = {
        let label = UILabel(frame: UIScreen.mainScreen().bounds)
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(80)

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

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)

        self.imageView.addGestureRecognizer(self.panGestureRecognizer)
    }

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self)
    }

    func panAction(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Changed:
            self.updatePosition(gesture)
            break
        default:
            break
        }
    }

    func updatePosition(gesture: UIPanGestureRecognizer) {
        let point = gesture.translationInView(self.view)
        gesture.view!.center = point
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
