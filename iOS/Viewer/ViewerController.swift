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
    var indexPath: NSIndexPath
    var collectionView: UICollectionView

    // MARK: - Initializers

    init(indexPath: NSIndexPath, collectionView: UICollectionView) {
        self.indexPath = indexPath
        self.collectionView = collectionView

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.modalPresentationStyle = .OverCurrentContext
        self.view.backgroundColor = UIColor.clearColor()
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.indexPath)
    }

    func presentedViewCopy(frame: CGRect) -> UIImageView {
        let window = UIApplication.sharedApplication().delegate!.window!!
        let presentedView = UIImageView(frame: window.convertRect(frame, fromView: self.collectionView))
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
    }

    func present(indexPath: NSIndexPath) {
        guard let window = UIApplication.sharedApplication().delegate?.window?!, selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath), items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError("Data source not implemented") }

        window.addSubview(self.overlayView)
        selectedCell.alpha = 0

        let presentedView = self.presentedViewCopy(selectedCell.frame)
        presentedView.image = image
        window.addSubview(presentedView)
        let centeredImageFrame = image.centeredFrame()

        UIView.animateWithDuration(0.25, animations: {
            self.overlayView.alpha = 1.0
            presentedView.frame = centeredImageFrame
            }) { completed in
                selectedCell.alpha = 1
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()

                self.setInitialController(indexPath.row)
        }
    }

    private func setInitialController(index: Int) {
        let initialViewController = self.findOrCreateViewerItemController(index)
        self.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
    }

    private func findOrCreateViewerItemController(index: Int) -> ViewerItemController {
        let viewerItems = self.controllerDataSource!.viewerItemsForViewerController(self)
        let viewerItem = viewerItems[index]
        var viewerItemController: ViewerItemController

        if let cachedController = self.viewerItemControllerCache.objectForKey(viewerItem.id) as? ViewerItemController {
            viewerItemController = cachedController
        } else {
            viewerItemController = ViewerItemController()
            viewerItemController.controllerDelegate = self
            self.viewerItemControllerCache.setObject(viewerItemController, forKey: viewerItem.id)
        }

        viewerItemController.viewerItem = viewerItem
        viewerItemController.index = index

        return viewerItemController
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController {
            let index = viewerItemController.index
            if index > 0 {
                let newIndex = index - 1
                self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: newIndex, inSection: 0))
                return self.findOrCreateViewerItemController(newIndex)
            }
        }

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) {
            let index = viewerItemController.index
            if index < viewerItems.count - 1 {
                let newIndex = index + 1
                self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: newIndex, inSection: 0))
                return self.findOrCreateViewerItemController(newIndex)
            }
        }

        return nil
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController) {
        let indexPath = NSIndexPath(forRow: viewerItemController.index, inSection: 0)
        guard let window = UIApplication.sharedApplication().delegate?.window?!, selectedCellFrame = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)?.frame, items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError() }

        if let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
            selectedCell.alpha = 0
        }

        viewerItemController.view.alpha = 0

        let presentedView = self.presentedViewCopy(selectedCellFrame)
        presentedView.image = image
        window.addSubview(presentedView)

        let centeredImageFrame = image.centeredFrame()
        presentedView.frame = centeredImageFrame

        self.overlayView.alpha = 1.0
        overlayView.frame = UIScreen.mainScreen().bounds
        window.addSubview(overlayView)
        window.addSubview(presentedView)

        UIView.animateWithDuration(0.30, animations: {
            self.overlayView.alpha = 0.0
            presentedView.frame = window.convertRect(selectedCellFrame, fromView: self.collectionView)
            }) { completed in
                if let existingCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                    existingCell.alpha = 1
                }

                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.dismissViewControllerAnimated(false, completion: nil)
                self.controllerDelegate?.viewerControllerDidDismiss(self)
        }
    }
}
