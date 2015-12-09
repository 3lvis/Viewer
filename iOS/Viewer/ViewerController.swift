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
    var indexPath: NSIndexPath
    var existingCell: UICollectionViewCell
    var collectionView: UICollectionView

    // MARK: - Initializers

    init(indexPath: NSIndexPath, collectionView: UICollectionView) {
        self.pageIndex = indexPath.row
        self.indexPath = indexPath
        self.existingCell = collectionView.cellForItemAtIndexPath(indexPath)!
        self.collectionView = collectionView

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.modalPresentationStyle = .OverCurrentContext
        self.view.backgroundColor = UIColor.clearColor()
        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    // MARK: View Lifecycle

    var cell: UIImageView?
    var originalRect = CGRectZero

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        present()
    }

    func present() {
        guard let window = UIApplication.sharedApplication().delegate?.window?! else { return }

        window.addSubview(overlayView)
        existingCell.alpha = 0

        let convertedRect = window.convertRect(existingCell.frame, fromView: collectionView)
        self.originalRect = convertedRect
        let transformedCell = UIImageView(frame: convertedRect)
        transformedCell.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        transformedCell.contentMode = .ScaleAspectFill
        transformedCell.clipsToBounds = true

        if let items = self.controllerDataSource?.viewerItemsForViewerController(self) {
            let item = items[indexPath.row]
            transformedCell.image = item.image
            window.addSubview(transformedCell)

            let screenBound = UIScreen.mainScreen().bounds
            let scaleFactor = transformedCell.image!.size.width / screenBound.size.width
            let finalImageViewFrame = CGRectMake(0, (screenBound.size.height/2) - ((transformedCell.image!.size.height / scaleFactor)/2), screenBound.size.width, transformedCell.image!.size.height / scaleFactor)

            UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.CurveEaseInOut, .BeginFromCurrentState, .AllowUserInteraction], animations: {
                self.overlayView.alpha = 1.0
                transformedCell.frame = finalImageViewFrame
                }) { completed in
                    transformedCell.removeFromSuperview()
                    self.cell = transformedCell
                    self.overlayView.removeFromSuperview()

                    self.setInitialController()
            }
        }
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
        viewerItemController.view.alpha = 0

        let screenBound = UIScreen.mainScreen().bounds
        let transformedCell = self.cell!
        let scaleFactor = transformedCell.image!.size.width / screenBound.size.width
        transformedCell.frame = CGRectMake(0, (screenBound.size.height/2) - ((transformedCell.image!.size.height / scaleFactor)/2), screenBound.size.width, transformedCell.image!.size.height / scaleFactor)

        self.overlayView.alpha = 1.0
        guard let window = UIApplication.sharedApplication().delegate?.window?! else { return }
        window.addSubview(overlayView)
        window.addSubview(transformedCell)

        UIView.animateWithDuration(0.30, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.CurveEaseInOut, .BeginFromCurrentState, .AllowUserInteraction], animations: {
            self.overlayView.alpha = 0.0
            transformedCell.frame = self.originalRect
            }) { completed in
                if let existingCell = self.collectionView.cellForItemAtIndexPath(self.indexPath) {
                    existingCell.alpha = 1
                }

                transformedCell.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.dismissViewControllerAnimated(false, completion: nil)
                self.controllerDelegate?.viewerControllerDidDismiss(self)
        }
    }
}
