import UIKit
import CoreData

/*
The ViewerController takes care of displaying the user's photos/videos in full-screen.

You can swipe right or left to navigate between photos.

When the ViewerController jumps betweeetn photos it triggers a call to the viewerControllerDidChangeIndexPath delegate.
*/

protocol ViewerControllerDataSource: class {
    func viewerItemsForViewerController(viewerController: ViewerController) -> [ViewerItem]
}

protocol ViewerControllerDelegate: class {
    func viewerController(viewerController: ViewerController, didChangeIndexPath indexPath: NSIndexPath)
    func viewerControllerDidDismiss(viewerController: ViewerController)
}

class ViewerController: UIPageViewController {
    weak var controllerDelegate: ViewerControllerDelegate?
    weak var controllerDataSource: ViewerControllerDataSource?
    let viewerItemControllerCache = NSCache()
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

        self.view.backgroundColor = UIColor.purpleColor()

        self.setInitialController()
    }

    private func setInitialController() {
        if let viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) {
            let initialViewController = self.viewerItemController(viewerItems[self.pageIndex])
            self.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
        }
    }

    private func viewerItemController(viewerItem: ViewerItem) -> ViewerItemController {
        var viewerItemController: ViewerItemController

        if let cachedController = self.viewerItemControllerCache.objectForKey(viewerItem.id) as? ViewerItemController {
            viewerItemController = cachedController
        } else {
            viewerItemController = ViewerItemController()
            viewerItemController.controllerDelegate = self
            self.viewerItemControllerCache.setObject(viewerItemController, forKey: viewerItem.id)
        }

        viewerItemController.viewerItem = viewerItem

        return viewerItemController
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, viewerItem = viewerItemController.viewerItem, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) {
            let index = viewerItems.indexOf({ $0.id == viewerItem.id })!
            if index > 0 {
                let previousItem = viewerItems[index - 1]
                return self.viewerItemController(previousItem)
            }
        }

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, viewerItem = viewerItemController.viewerItem, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) {
            let index = viewerItems.indexOf({ $0.id == viewerItem.id })!
            if index < viewerItems.count - 1 {
                let previousItem = viewerItems[index + 1]
                return self.viewerItemController(previousItem)
            }
        }

        return nil
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController) {
        self.controllerDelegate?.viewerControllerDidDismiss(self)
    }
}
