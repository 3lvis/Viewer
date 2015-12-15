import UIKit
import CoreData

/**
The ViewerController takes care of displaying the user's photos/videos in full-screen.

You can swipe right or left to navigate between photos.
*/

public protocol ViewerControllerDataSource: class {
    func viewerItemsForViewerController(viewerController: ViewerController) -> [ViewerItem]
}

public protocol ViewerControllerDelegate: class {
    /**
    When the ViewerController jumps between photos it triggers a call to the viewerController:didChangeIndexPath: delegate
    */
    func viewerController(viewerController: ViewerController, didChangeIndexPath indexPath: NSIndexPath)

    /**
    When the ViewerController is dismissed it triggers a call to the viewerControllerDidDismiss: delegate
    */
    func viewerControllerDidDismiss(viewerController: ViewerController)
}

public class ViewerController: UIPageViewController {
    // MARK: Initializers

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

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Variables

    weak var controllerDelegate: ViewerControllerDelegate?
    weak var controllerDataSource: ViewerControllerDataSource?

    /**
     Cache for the reused ViewerItemControllers
     */
    private let viewerItemControllerCache = NSCache()

    /**
    Temporary variable used to present the initial controller on viewDidAppear
    */
    private var initialIndexPath: NSIndexPath

    /**
     The UICollectionView to be used when dismissing and presenting elements
     */
    unowned var collectionView: UICollectionView

    /**
     CGPoint used for diffing the panning on an image
     */
    var originalDraggedCenter = CGPointZero

    /**
     Used for doing a different animation when dismissing in the middle of a dragging gesture
     */
    var isDragging = false

    /**
     Keeps track of where the status bar should be hidden or not
     */
    var shouldHideStatusBar = false

    lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    lazy var headerView: UIView = {
        let bounds = UIScreen.mainScreen().bounds
        let view = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 50))
        view.backgroundColor = UIColor.redColor()
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleWidth]
        view.alpha = 0

        return view
    }()

    lazy var footerView: UIView = {
        let bounds = UIScreen.mainScreen().bounds
        let y = bounds.size.height - 50
        let view = UIView(frame: CGRect(x: 0, y: y, width: bounds.width, height: 50))
        view.backgroundColor = UIColor.greenColor()
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin, .FlexibleWidth]
        view.alpha = 0

        return view
    }()

    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: "panAction:")
        gesture.delegate = self

        return gesture
    }()

    // MARK: View Lifecycle

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.initialIndexPath)
    }

    public override func prefersStatusBarHidden() -> Bool {
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if UIInterfaceOrientationIsLandscape(orientation) {
            return true
        }

        return self.shouldHideStatusBar
    }

    // MARK: Private methods

    func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
    }

    private func setInitialController(index: Int) {
        let controller = self.findOrCreateViewerItemController(index)
        controller.imageView.tag = controller.index
        controller.imageView.addGestureRecognizer(self.panGestureRecognizer)
        self.setViewControllers([controller], direction: .Forward, animated: false, completion: { finished in
            self.toogleButtons(true)
        })
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

    public func toogleButtons(shouldShow: Bool) {
        UIView.animateWithDuration(0.3) {
            self.headerView.alpha = shouldShow ? 1 : 0
            self.footerView.alpha = shouldShow ? 1 : 0
        }
    }

    public func fadeButtons(alpha: CGFloat) {
        self.headerView.alpha = alpha
        self.footerView.alpha = alpha
    }
}

// MARK: Core Methods

extension ViewerController {
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

        window.addSubview(self.headerView)
        window.addSubview(self.footerView)

        self.shouldHideStatusBar = true
        UIView.animateWithDuration(0.25, animations: {
            self.overlayView.alpha = 1.0
            self.setNeedsStatusBarAppearanceUpdate()
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
        self.toogleButtons(false)

        let presentedView = self.presentedViewCopy()
        presentedView.frame = image.centeredFrame()
        presentedView.image = image

        if self.isDragging {
            presentedView.center = viewerItemController.imageView.center
            self.overlayView.alpha = CGColorGetAlpha(viewerItemController.view.backgroundColor!.CGColor)
        } else {
            self.overlayView.alpha = 1.0
        }

        self.overlayView.frame = UIScreen.mainScreen().bounds
        let window = self.applicationWindow()
        window.addSubview(self.overlayView)
        window.addSubview(presentedView)
        self.shouldHideStatusBar = false

        UIView.animateWithDuration(0.30, animations: {
            self.fadeButtons(0)
            self.overlayView.alpha = 0.0
            self.setNeedsStatusBarAppearanceUpdate()
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
        let controller = self.findOrCreateViewerItemController(gesture.view!.tag)

        let viewHeight = controller.imageView.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translationInView(controller.imageView)

        if gesture.state == .Began {
            self.originalDraggedCenter = controller.imageView.center
            self.isDragging = true
        }

        translatedPoint = CGPoint(x: self.originalDraggedCenter.x, y: self.originalDraggedCenter.y + translatedPoint.y)
        let alphaDiff = ((translatedPoint.y - viewHalfHeight) / viewHalfHeight) * 2.5
        let isDraggedUp = translatedPoint.y < viewHalfHeight
        let alpha = isDraggedUp ? 1 + alphaDiff : 1 - alphaDiff

        controller.imageView.center = translatedPoint
        controller.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(alpha)
        self.fadeButtons(alpha)

        if gesture.state == .Ended {
            let draggingMargin = CGFloat(60)
            let centerAboveDraggingArea = controller.imageView.center.y < viewHalfHeight - draggingMargin
            let centerBellowDraggingArea = controller.imageView.center.y > viewHalfHeight + draggingMargin
            if centerAboveDraggingArea || centerBellowDraggingArea {
                self.dismiss(controller, completion: nil)
            } else {
                self.isDragging = false
                UIView.animateWithDuration(0.20, animations: {
                    controller.imageView.center = self.originalDraggedCenter
                    controller.view.backgroundColor = UIColor.blackColor()
                    self.fadeButtons(1)
                })
            }
        }
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewerItemController = viewController as? ViewerItemController where viewerItemController.index > 0  else { return nil }

        let newIndex = viewerItemController.index - 1
        let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
        let controller = self.findOrCreateViewerItemController(newIndex)

        return controller
    }

    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewerItemController = viewController as? ViewerItemController, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) where viewerItemController.index < viewerItems.count - 1 else { return nil }

        let newIndex = viewerItemController.index + 1
        let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 0)
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
        let controller = self.findOrCreateViewerItemController(newIndex)

        return controller
    }
}

extension ViewerController: UIPageViewControllerDelegate {
    public func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        guard let controllers = pendingViewControllers as? [ViewerItemController] else { fatalError() }

        for controller in controllers {
            controller.imageView.addGestureRecognizer(self.panGestureRecognizer)
            controller.imageView.tag = controller.index
            let newIndexPath = NSIndexPath(forRow: controller.index, inSection: 0)
            if let newCell = self.collectionView.cellForItemAtIndexPath(newIndexPath) {
                newCell.alpha = 0
            }
        }
    }

    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
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
    public func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        dismiss(viewerItemController, completion: completion)
    }
}

extension ViewerController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGestureRecognizer {
            let velocity = self.panGestureRecognizer.velocityInView(panGestureRecognizer.view!)
            let allowOnlyVerticalScrolls = fabs(velocity.y) > fabs(velocity.x)

            return allowOnlyVerticalScrolls
        }

        return true
    }
}
