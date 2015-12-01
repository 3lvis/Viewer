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
    func viewerController(viewerController: ViewerController, viewItemAtIndex index: Int)
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
        let initialViewController = self.dataItemViewControllerForPage(pageIndex)
        self.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
    }

    private func indexOfDataItemForViewController(viewController: UIViewController) -> Int {
        guard let viewController = viewController as? ViewerItemController else { fatalError("Unexpected view controller type in page view controller.") }
        let indexPath = self.controllerDataSource?.viewerController(self, viewItemAtIndex: )

        self.fetchedResultsController.indexPathForObject(viewController.timelineItem!)

        return indexPath?.row ?? 0
    }

    private func dataItemViewControllerForPage(pageIndex: Int) -> ViewerItemController {
        guard let timelineItem = self.fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: pageIndex, inSection: 0)) as? TimelineItem, remoteID = timelineItem.remoteID else { fatalError("No photo was found for the current pageIndex") }

        var viewerItemController: ViewerItemController

        if let cachedController = self.dataItemViewControllerCache.objectForKey(remoteID) as? ViewerItemController {
            viewerItemController = cachedController
        } else {
            viewerItemController = ViewerItemController(fetcher: self.fetcher)
            viewerItemController.controllerDelegate = self
            self.dataItemViewControllerCache.setObject(viewerItemController, forKey: remoteID)
        }

        viewerItemController.timelineItem = timelineItem

        return viewerItemController
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let index = self.indexOfDataItemForViewController(viewController)

        self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: index, inSection: 0))

        return index > 0 ? self.dataItemViewControllerForPage(index - 1) : nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let index = indexOfDataItemForViewController(viewController)

        self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: index, inSection: 0))

        return index < self.fetchedResultsController.fetchedObjects!.count - 1 ? self.dataItemViewControllerForPage(index + 1) : nil
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController) {
        self.controllerDelegate?.viewerControllerDidDismiss(self)
    }
}
