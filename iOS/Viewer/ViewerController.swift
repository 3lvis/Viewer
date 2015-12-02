import UIKit
import CoreData

/*
The ViewerController takes care of displaying the user's photos/videos in full-screen.

You can swipe right or left to navigate between photos.

When the ViewerController jumps betweeetn photos it triggers a call to the viewerControllerDidChangeIndexPath delegate.
*/

protocol ViewerItem {
    var remoteID: String { get }
    var image: UIImage { get }
}

protocol ViewerControllerDataSource: class {
    func elementsForViewerController(viewerController: ViewerController) -> [ViewerItem]
    func viewerController(viewerController: ViewerController, viewItemAtIndex index: Int) -> ViewerItem
}

protocol ViewerControllerDelegate: class {
    func viewerController(viewerController: ViewerController, didChangeIndexPath indexPath: NSIndexPath)
    func viewerControllerDidDismiss(viewerController: ViewerController)
}

class ViewerController: UIPageViewController {
    weak var controllerDelegate: ViewerControllerDelegate?
    weak var controllerDataSource: ViewerControllerDataSource?
    let dataItemViewControllerCache = NSCache()
    var pageIndex = 0

    // MARK: - Initializers

    init(pageIndex: Int) {
        self.pageIndex = pageIndex

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.blackColor()

        self.setInitialController()
    }

    private func setInitialController() {
        if let viewerItem = self.controllerDataSource?.viewerController(self, viewItemAtIndex: self.pageIndex), initialViewController = self.dataItemViewControllerCache.objectForKey(viewerItem.remoteID) as? ViewerItemController {
            self.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
        }
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        // get ViewerItem from viewController
        // indexForViewerItem

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController) {
        self.controllerDelegate?.viewerControllerDidDismiss(self)
    }
}
