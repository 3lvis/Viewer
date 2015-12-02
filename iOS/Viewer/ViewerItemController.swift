import UIKit

protocol ViewerItemControllerDelegate: class {
    // func viewerItemController(viewerItemController: ViewerItemController, imageForViewerItem viewerItem: ViewerItem)
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    var viewerItem: ViewerItem? {
        didSet {
            self.imageView.alpha = 1
        }
    }

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.greenColor()
        view.contentMode = .ScaleAspectFit
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.imageView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self)
    }
}
