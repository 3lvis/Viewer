import UIKit

protocol ViewerItemControllerDelegate: class {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController)
}

class ViewerItemController: UIViewController {
    weak var controllerDelegate: ViewerItemControllerDelegate?

    var viewerItem: ViewerItem? {
        didSet {
             self.label.text = String(viewerItem?.id ?? 0)
        }
    }

    lazy var label: UILabel = {
        let label = UILabel(frame: UIScreen.mainScreen().bounds)
        label.backgroundColor = UIColor.redColor()
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(30)

        return label
    }()

    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.greenColor()
        view.contentMode = .ScaleAspectFit
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.orangeColor()
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.label)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAction")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    func tapAction() {
        self.controllerDelegate?.viewerItemControllerDidTapItem(self)
    }
}
