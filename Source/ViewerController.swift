import UIKit
import CoreData

/**
 The ViewerController takes care of displaying the user's photos/videos in full-screen.

 You can swipe right or left to navigate between photos.
 */

public protocol ViewerControllerDataSource: class {
    func viewerController(viewerController: ViewerController, itemAtIndexPath indexPath: NSIndexPath) -> ViewerItem
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
    private static let HeaderHeight = CGFloat(64)
    private static let FooterHeight = CGFloat(50)
    private static let DraggingMargin = CGFloat(60)

    // MARK: Initializers

    public init(initialIndexPath: NSIndexPath, collectionView: UICollectionView, headerViewClass: AnyClass, footerViewClass: AnyClass) {
        self.initialIndexPath = initialIndexPath
        self.currentIndexPath = initialIndexPath
        self.proposedCurrentIndexPath = initialIndexPath
        self.collectionView = collectionView
        self.headerViewClass = headerViewClass
        self.footerViewClass = footerViewClass

        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

        self.dataSource = self
        self.delegate = self
        self.view.backgroundColor = UIColor.clearColor()
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.modalPresentationStyle = .OverCurrentContext
        self.presentingViewController?.modalPresentationCapturesStatusBarAppearance = true
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Variables

    public weak var controllerDelegate: ViewerControllerDelegate?
    public weak var controllerDataSource: ViewerControllerDataSource?

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
    private unowned var collectionView: UICollectionView

    /**
     CGPoint used for diffing the panning on an image
     */
    private var originalDraggedCenter = CGPointZero

    /**
     Used for doing a different animation when dismissing in the middle of a dragging gesture
     */
    private var isDragging = false

    /**
     Keeps track of where the status bar should be hidden or not
     */
    private var shouldHideStatusBar = false

    /**
     Keeps track of where the status bar should be light or not
     */
    private var shouldUseLightStatusBar = true

    /**
     Critical button visibility state tracker, it's used to force the buttons to keep being hidden when they are toggled
     */
    private var buttonsAreVisible = false

    /**
     Tracks the index for the current viewer item controller
     */
    private var currentIndexPath: NSIndexPath

    /**
     Tracks the index to be, it will be ignored if the swiping transition is not finished
     */
    private var proposedCurrentIndexPath: NSIndexPath

    private lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    private let headerViewClass: AnyClass

    private lazy var headerView: UIView = {
        let headerClass = self.headerViewClass as! UIView.Type
        let view = headerClass.init()
        let bounds = UIScreen.mainScreen().bounds
        view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: ViewerController.HeaderHeight)
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleWidth]
        view.alpha = 0

        return view
    }()

    private let footerViewClass: AnyClass

    private lazy var footerView: UIView = {
        let bounds = UIScreen.mainScreen().bounds
        let footerClass = self.footerViewClass as! UIView.Type
        let view = footerClass.init()
        view.frame = CGRect(x: 0, y: bounds.size.height - ViewerController.FooterHeight, width: bounds.width, height: ViewerController.FooterHeight)
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

    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if self.shouldUseLightStatusBar {
            return .LightContent
        } else {
            return self.presentingViewController?.preferredStatusBarStyle() ?? .Default
        }
    }

    // MARK: Private methods

    private func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
    }

    private func findOrCreateViewerItemController(indexPath: NSIndexPath) -> ViewerItemController {
        let viewerItem = self.controllerDataSource!.viewerController(self, itemAtIndexPath: indexPath)
        var viewerItemController: ViewerItemController

        if let cachedController = self.viewerItemControllerCache.objectForKey(viewerItem.remoteID!) as? ViewerItemController {
            viewerItemController = cachedController
        } else {
            viewerItemController = ViewerItemController()
            viewerItemController.controllerDelegate = self

            let gesture = UIPanGestureRecognizer(target: self, action: "panAction:")
            gesture.delegate = self
            viewerItemController.imageView.addGestureRecognizer(gesture)

            self.viewerItemControllerCache.setObject(viewerItemController, forKey: viewerItem.remoteID!)
        }

        viewerItemController.viewerItem = viewerItem
        viewerItemController.indexPath = indexPath

        return viewerItemController
    }

    private func toggleButtons(shouldShow: Bool) {
        UIView.animateWithDuration(0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
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
        guard let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) else { fatalError("Data source not implemented") }

        let viewerItem = self.controllerDataSource!.viewerController(self, itemAtIndexPath: indexPath)
        let image = viewerItem.placeholder
        selectedCell.alpha = 0

        let window = self.applicationWindow()

        let presentedView = self.presentedViewCopy()
        presentedView.frame = window.convertRect(selectedCell.frame, fromView: self.collectionView)
        presentedView.image = image

        window.addSubview(self.overlayView)
        window.addSubview(presentedView)
        window.addSubview(self.headerView)
        window.addSubview(self.footerView)

        let centeredImageFrame = image.centeredFrame()
        UIView.animateWithDuration(0.25, animations: {
            self.overlayView.alpha = 1.0
            self.setNeedsStatusBarAppearanceUpdate()
            presentedView.frame = centeredImageFrame
            }) { completed in
                self.presentingViewController?.tabBarController?.tabBar.alpha = 0
                let controller = self.findOrCreateViewerItemController(indexPath)
                self.setViewControllers([controller], direction: .Forward, animated: false, completion: { finished in
                    self.toggleButtons(true)
                    self.buttonsAreVisible = true
                    self.currentIndexPath = indexPath
                    presentedView.removeFromSuperview()
                    self.overlayView.removeFromSuperview()
                    self.view.backgroundColor = UIColor.blackColor()

                    completion?()
                })
        }
    }

    public func dismiss(completion: (() -> Void)?) {
        let controller = self.findOrCreateViewerItemController(self.currentIndexPath)
        self.dismiss(controller, completion: completion)
    }

    private func dismiss(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        guard let selectedCellFrame = self.collectionView.layoutAttributesForItemAtIndexPath(viewerItemController.indexPath!)?.frame else { fatalError() }

        let viewerItem = self.controllerDataSource!.viewerController(self, itemAtIndexPath: viewerItemController.indexPath!)
        let image = viewerItem.placeholder
        viewerItemController.imageView.alpha = 0
        viewerItemController.view.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = UIColor.clearColor()
        self.fadeButtons(0)
        self.buttonsAreVisible = false
        self.updateHiddenCellsUsingVisibleIndexPath(self.currentIndexPath)

        self.shouldHideStatusBar = false
        self.setNeedsStatusBarAppearanceUpdate()

        self.overlayView.alpha = self.isDragging ? CGColorGetAlpha(viewerItemController.view.backgroundColor!.CGColor) : 1.0
        self.overlayView.frame = UIScreen.mainScreen().bounds

        let presentedView = self.presentedViewCopy()
        presentedView.frame = image.centeredFrame()
        presentedView.image = image
        if self.isDragging {
            presentedView.center = viewerItemController.imageView.center
        }

        let window = self.applicationWindow()
        window.addSubview(self.overlayView)
        window.addSubview(presentedView)
        self.shouldUseLightStatusBar = false

        UIView.animateWithDuration(0.30, animations: {
            self.presentingViewController?.tabBarController?.tabBar.alpha = 1
            self.overlayView.alpha = 0.0
            self.setNeedsStatusBarAppearanceUpdate()
            presentedView.frame = window.convertRect(selectedCellFrame, fromView: self.collectionView)
            }) { completed in
                if let existingCell = self.collectionView.cellForItemAtIndexPath(viewerItemController.indexPath!) {
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

    /*
    Has to be internal since it's used as an action
    */
    func panAction(gesture: UIPanGestureRecognizer) {
        let controller = self.findOrCreateViewerItemController(self.currentIndexPath)
        let viewHeight = controller.imageView.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translationInView(controller.imageView)

        if gesture.state == .Began {
            self.shouldHideStatusBar = false
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.backgroundColor = UIColor.clearColor()
            self.originalDraggedCenter = controller.imageView.center
            self.isDragging = true
            self.updateHiddenCellsUsingVisibleIndexPath(self.currentIndexPath)
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
            let centerAboveDraggingArea = controller.imageView.center.y < viewHalfHeight - ViewerController.DraggingMargin
            let centerBellowDraggingArea = controller.imageView.center.y > viewHalfHeight + ViewerController.DraggingMargin
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
                        self.shouldHideStatusBar = false
                        self.shouldUseLightStatusBar = true
                        self.setNeedsStatusBarAppearanceUpdate()
                        self.view.backgroundColor = UIColor.blackColor()
                }
            }
        }
    }

    private func centerElementIfNotVisible(indexPath: NSIndexPath) {
        if !self.collectionView.indexPathsForVisibleItems().contains(indexPath) {
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }

    private func updateHiddenCellsUsingVisibleIndexPath(visibleIndexPath: NSIndexPath) {
        for indexPath in self.collectionView.indexPathsForVisibleItems() {
            if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                cell.alpha = indexPath == visibleIndexPath ? 0 : 1
            }
        }
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, newIndexPath = viewerItemController.indexPath?.previous(self.collectionView) {
            self.centerElementIfNotVisible(newIndexPath)
            self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
            let controller = self.findOrCreateViewerItemController(newIndexPath)

            return controller
        }

        return nil
    }

    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, newIndexPath = viewerItemController.indexPath?.next(self.collectionView) {
            self.centerElementIfNotVisible(newIndexPath)
            self.controllerDelegate?.viewerController(self, didChangeIndexPath: newIndexPath)
            let controller = self.findOrCreateViewerItemController(newIndexPath)

            return controller
        }

        return nil
    }
}

extension ViewerController: UIPageViewControllerDelegate {
    public func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        guard let controllers = pendingViewControllers as? [ViewerItemController] else { fatalError() }

        for controller in controllers {
            self.proposedCurrentIndexPath = controller.indexPath!
        }
    }

    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            self.currentIndexPath = self.proposedCurrentIndexPath
        }
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> Void)?) {
        self.shouldHideStatusBar = !self.shouldHideStatusBar
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
