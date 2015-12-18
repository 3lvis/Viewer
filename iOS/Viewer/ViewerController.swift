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
    static let HeaderFooterHeight = CGFloat(50)

    // MARK: Initializers

    init(initialIndexPath: NSIndexPath, collectionView: UICollectionView, headerViewClass: AnyClass, footerViewClass: AnyClass) {
        self.initialIndexPath = initialIndexPath
        self.collectionView = collectionView
        self.headerViewClass = headerViewClass
        self.footerViewClass = footerViewClass

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.modalPresentationStyle = .OverCurrentContext
        self.view.backgroundColor = UIColor.clearColor()
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.dataSource = self
        self.delegate = self
        self.presentingViewController?.modalPresentationCapturesStatusBarAppearance = true
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

    /**
     Critical button visibility state tracker, it's used to force the buttons to keep being hidden when they are toggled
     */
    var buttonsAreVisible = false

    /**
     Tracks the index for the current viewer item controller
     */
    var currentIndex = 0

    /**
     Tracks the index to be, it will be ignored if the swiping transition is not finished
     */
    var proposedCurrentIndex = 0

    lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    let headerViewClass: AnyClass

    lazy var headerView: UIView = {
        let headerClass = self.headerViewClass as! UIView.Type
        let view = headerClass.init()
        let bounds = UIScreen.mainScreen().bounds
        view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: ViewerController.HeaderFooterHeight)
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleWidth]
        view.alpha = 0

        return view
    }()

    let footerViewClass: AnyClass

    lazy var footerView: UIView = {
        let bounds = UIScreen.mainScreen().bounds
        let footerClass = self.footerViewClass as! UIView.Type
        let view = footerClass.init()
        view.frame = CGRect(x: 0, y: bounds.size.height - ViewerController.HeaderFooterHeight, width: bounds.width, height: ViewerController.HeaderFooterHeight)
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin, .FlexibleWidth]
        view.alpha = 0

        return view
    }()

    // MARK: View Lifecycle

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.initialIndexPath, completion: nil)
    }

    public override func prefersStatusBarHidden() -> Bool {
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if UIInterfaceOrientationIsLandscape(orientation) {
            return true
        }

        return self.shouldHideStatusBar
    }

    // MARK: Private methods

    private func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
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

            let gesture = UIPanGestureRecognizer(target: self, action: "panAction:")
            gesture.delegate = self
            viewerItemController.imageView.addGestureRecognizer(gesture)

            self.viewerItemControllerCache.setObject(viewerItemController, forKey: viewerItem.id)
        }

        viewerItemController.viewerItem = viewerItem
        viewerItemController.index = index

        return viewerItemController
    }

    private func toggleButtons(shouldShow: Bool) {
        UIView.animateWithDuration(0.3) {
            self.headerView.alpha = shouldShow ? 1 : 0
            self.footerView.alpha = shouldShow ? 1 : 0
        }
    }

    private func fadeButtons(alpha: CGFloat) {
        self.headerView.alpha = alpha
        self.footerView.alpha = alpha
    }
}

// MARK: Core Methods

extension ViewerController {
    private func present(indexPath: NSIndexPath, completion: (() -> Void)?) {
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
                self.view.backgroundColor = UIColor.blackColor()

                let controller = self.findOrCreateViewerItemController(indexPath.row)
                controller.imageView.tag = controller.index
                self.setViewControllers([controller], direction: .Forward, animated: false, completion: { finished in
                    self.toggleButtons(true)
                    self.buttonsAreVisible = true
                    self.currentIndex = indexPath.row

                    completion?()
                })
        }
    }

    func dismiss(completion: (() -> Void)?) {
        let controller = self.findOrCreateViewerItemController(self.currentIndex)
        self.dismiss(controller, completion: completion)
    }

    private func dismiss(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        let indexPath = NSIndexPath(forRow: viewerItemController.index, inSection: 0)
        guard let selectedCellFrame = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)?.frame, items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError() }

        if let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
            selectedCell.alpha = 0
        }

        viewerItemController.imageView.alpha = 0
        viewerItemController.view.backgroundColor = UIColor.clearColor()
        self.fadeButtons(0)
        self.buttonsAreVisible = false

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
            self.overlayView.alpha = 0.0
            self.setNeedsStatusBarAppearanceUpdate()
            presentedView.frame = window.convertRect(selectedCellFrame, fromView: self.collectionView)
            }) { completed in
                if let existingCell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                    existingCell.alpha = 1
                }

                self.headerView.removeFromSuperview()
                self.footerView.removeFromSuperview()
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.dismissViewControllerAnimated(false, completion: nil)
                self.controllerDelegate?.viewerControllerDidDismiss(self)

                completion?()
        }
    }

    func panAction(gesture: UIPanGestureRecognizer) {
        self.view.backgroundColor = UIColor.clearColor()
        let controller = self.findOrCreateViewerItemController(self.currentIndex)

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

        if self.buttonsAreVisible == true {
            self.fadeButtons(alpha)
        }

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

                    if self.buttonsAreVisible == true {
                        self.fadeButtons(1)
                    }
                    }) { completed in
                        self.view.backgroundColor = UIColor.blackColor()
                }
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
            self.proposedCurrentIndex = controller.index
        }
    }

    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        if completed {
            self.currentIndex = self.proposedCurrentIndex

            for indexPath in self.collectionView.indexPathsForVisibleItems() {
                if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                    cell.alpha = indexPath.row == self.currentIndex ? 0 : 1
                }
            }
        }
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    public func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        self.buttonsAreVisible = !self.buttonsAreVisible
        self.toggleButtons(self.buttonsAreVisible)
    }
}

extension ViewerController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = panGestureRecognizer.velocityInView(panGestureRecognizer.view!)
            let allowOnlyVerticalScrolls = fabs(velocity.y) > fabs(velocity.x)

            return allowOnlyVerticalScrolls
        }

        return true
    }
}
