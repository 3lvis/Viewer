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
    var initialIndexPath: NSIndexPath
    var collectionView: UICollectionView
    var originalDraggedCenter = CGPointZero
    var isDragging = false
    var lastAlpha = CGFloat(0)
    var currentIndex = 0

    // MARK: - Initializers

    init(indexPath: NSIndexPath, collectionView: UICollectionView) {
        self.initialIndexPath = indexPath
        self.collectionView = collectionView

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.modalPresentationStyle = .OverCurrentContext
        self.view.backgroundColor = UIColor.clearColor()
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.dataSource = self
        self.delegate = self
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

    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: "panAction:")
        gesture.delegate = self

        return gesture
    }()

    // MARK: View Lifecycle

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.initialIndexPath)
    }

    // MARK: Private methods

    func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
    }

    func present(indexPath: NSIndexPath) {
        guard let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath), items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError("Data source not implemented") }

        let window = self.applicationWindow()
        window.addSubview(self.overlayView)
        selectedCell.alpha = 0

        let presentedView = self.presentedViewCopy()
        presentedView.frame = window.convertRect(selectedCell.frame, fromView: self.collectionView)

        presentedView.image = image
        window.addSubview(presentedView)
        let centeredImageFrame = image.centeredFrame()

        UIView.animateWithDuration(0.25, animations: {
            self.overlayView.alpha = 1.0
            presentedView.frame = centeredImageFrame
            }) { completed in
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()

                self.setInitialController(indexPath.row)
        }
    }

    func dismiss(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        let indexPath = NSIndexPath(forRow: viewerItemController.index, inSection: 0)
        guard let selectedCellFrame = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)?.frame, items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError() }

        if let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
            selectedCell.alpha = 0
        }

        viewerItemController.imageView.alpha = 0
        viewerItemController.view.backgroundColor = UIColor.clearColor()

        let presentedView = self.presentedViewCopy()
        presentedView.frame = image.centeredFrame()
        presentedView.image = image

        if self.isDragging {
            presentedView.center = viewerItemController.imageView.center
            self.overlayView.alpha = self.lastAlpha
        } else {
            self.overlayView.alpha = 1.0
        }

        self.overlayView.frame = UIScreen.mainScreen().bounds
        let window = self.applicationWindow()
        window.addSubview(self.overlayView)
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
                
                completion?()
        }
    }

    func panAction(gesture: UIPanGestureRecognizer) {
        let controller = self.findOrCreateViewerItemController(self.currentIndex)

        let viewHeight = controller.imageView.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translationInView(controller.imageView)

        if gesture.state == .Began {
            self.originalDraggedCenter = controller.imageView.center
            self.isDragging = true
            setNeedsStatusBarAppearanceUpdate()
        }

        translatedPoint = CGPoint(x: self.originalDraggedCenter.x, y: self.originalDraggedCenter.y + translatedPoint.y)
        let alphaDiff = ((translatedPoint.y - viewHalfHeight) / viewHalfHeight) * 2.5
        let isDraggedUp = translatedPoint.y < viewHalfHeight
        let alpha = isDraggedUp ? 1 + alphaDiff : 1 - alphaDiff

        self.lastAlpha = alpha

        controller.imageView.center = translatedPoint
        controller.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(alpha)

        if gesture.state == .Ended {
            let draggingMargin = CGFloat(60)
            let centerAboveDraggingArea = controller.imageView.center.y < viewHalfHeight - draggingMargin
            let centerBellowDraggingArea = controller.imageView.center.y > viewHalfHeight + draggingMargin
            if centerAboveDraggingArea || centerBellowDraggingArea {
                self.dismiss(controller, completion: nil)
            } else {
                self.isDragging = false
                controller.imageView.center = self.originalDraggedCenter
            }
        }
    }

    private func setInitialController(index: Int) {
        let controller = self.findOrCreateViewerItemController(index)
        self.currentIndex = controller.index
        controller.imageView.addGestureRecognizer(self.panGestureRecognizer)
        self.setViewControllers([controller], direction: .Forward, animated: false, completion: nil)
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
        guard let viewerItemController = viewController as? ViewerItemController where viewerItemController.index > 0  else { return nil }

        let newIndex = viewerItemController.index - 1
        let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
        let controller = self.findOrCreateViewerItemController(newIndex)

        return controller
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewerItemController = viewController as? ViewerItemController, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) where viewerItemController.index < viewerItems.count - 1 else { return nil }

        let newIndex = viewerItemController.index + 1
        let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
        let controller = self.findOrCreateViewerItemController(newIndex)

        return controller
    }
}

extension ViewerController: UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        guard let controllers = pendingViewControllers as? [ViewerItemController] else { fatalError() }

        for controller in controllers {
            controller.imageView.addGestureRecognizer(self.panGestureRecognizer)
            self.currentIndex = controller.index
            let newIndexPath = NSIndexPath(forRow: controller.index, inSection: 0)
            if let newCell = self.collectionView.cellForItemAtIndexPath(newIndexPath) {
                newCell.alpha = 0
            }
        }
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let controllers = previousViewControllers as? [ViewerItemController] else { fatalError() }

        for controller in controllers {
            controller.imageView.removeGestureRecognizer(self.panGestureRecognizer)
            let indexPath = NSIndexPath(forRow: controller.index, inSection: 0)
            if let currentCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                currentCell.alpha = 1
            }
        }
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        dismiss(viewerItemController, completion: completion)
    }
}

extension ViewerController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGestureRecognizer {
            let velocity = self.panGestureRecognizer.velocityInView(panGestureRecognizer.view!)
            let allowOnlyVerticalScrolls = fabs(velocity.y) > fabs(velocity.x)

            return allowOnlyVerticalScrolls
        }

        return true
    }
}
