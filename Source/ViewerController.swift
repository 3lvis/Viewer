import UIKit
import CoreData

/**
 The ViewerController takes care of displaying the user's photos/videos in full-screen.

 You can swipe right or left to navigate between photos.
 */

public protocol ViewerControllerDataSource: class {
    func numerOfItemsInViewerController(viewerController: ViewerController) -> Int
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

public class ViewerController: UIViewController {
    private static let HeaderHeight = CGFloat(64)
    private static let FooterHeight = CGFloat(50)
    private static let DraggingMargin = CGFloat(60)

    public init(initialIndexPath: NSIndexPath, collectionView: UICollectionView) {
        self.initialIndexPath = initialIndexPath
        self.currentIndexPath = initialIndexPath
        self.collectionView = collectionView

        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = UIColor.clearColor()
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.modalPresentationStyle = .OverCurrentContext
        #if os(iOS)
            self.presentingViewController?.modalPresentationCapturesStatusBarAppearance = true
        #endif
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
     A helper to prevent the paginated scroll view to be set up twice when is presented
     */
    private var presented = false

    private lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    public var headerView: UIView?

    public var footerView: UIView?

    lazy var scrollView: PaginatedScrollView = {
        let view = PaginatedScrollView(frame: self.view.frame, parentController: self, initialPage: self.initialIndexPath.totalRow(self.collectionView))
        view.viewDataSource = self
        view.viewDelegate = self
        view.backgroundColor = UIColor.clearColor()

        return view
    }()

    // MARK: View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.scrollView)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if presented {
            self.scrollView.configure()
            if !self.collectionView.indexPathsForVisibleItems().contains(self.currentIndexPath) {
                self.collectionView.scrollToItemAtIndexPath(self.currentIndexPath, atScrollPosition: .Bottom, animated: true)
            }
        }
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.initialIndexPath, completion: nil)
    }
}

extension ViewerController {
    #if os(iOS)
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
    #endif

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
            viewerItemController.controllerDataSource = self

            let gesture = UIPanGestureRecognizer(target: self, action: #selector(ViewerController.panAction(_:)))
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
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            self.headerView?.alpha = shouldShow ? 1 : 0
            self.footerView?.alpha = shouldShow ? 1 : 0
        }
    }

    private func fadeButtons(alpha: CGFloat) {
        self.headerView?.alpha = alpha
        self.footerView?.alpha = alpha
    }

    private func present(indexPath: NSIndexPath, completion: (() -> Void)?) {
        guard let selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) else { fatalError("Data source not implemented") }

        let viewerItem = self.controllerDataSource!.viewerController(self, itemAtIndexPath: indexPath)
        let image = viewerItem.placeholder
        selectedCell.alpha = 0

        let presentedView = self.presentedViewCopy()
        presentedView.frame = self.view.convertRect(selectedCell.frame, fromView: self.collectionView)
        presentedView.image = image

        self.view.addSubview(self.overlayView)
        self.view.addSubview(presentedView)

        if let headerView = self.headerView {
            let bounds = UIScreen.mainScreen().bounds
            headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: ViewerController.HeaderHeight)
            headerView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleWidth]
            headerView.alpha = 0
            self.view.addSubview(headerView)
        }

        if let footerView = self.footerView {
            let bounds = UIScreen.mainScreen().bounds
            footerView.frame = CGRect(x: 0, y: bounds.size.height - ViewerController.FooterHeight, width: bounds.width, height: ViewerController.FooterHeight)
            footerView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin, .FlexibleWidth]
            footerView.alpha = 0
            self.view.addSubview(footerView)
        }

        let centeredImageFrame = image.centeredFrame()
        UIView.animateWithDuration(0.25, animations: {
            self.presentingViewController?.tabBarController?.tabBar.alpha = 0
            self.overlayView.alpha = 1.0
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            presentedView.frame = centeredImageFrame
            }) { completed in
                self.toggleButtons(true)
                self.buttonsAreVisible = true
                self.currentIndexPath = indexPath
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.view.backgroundColor = UIColor.blackColor()
                self.presented = true
                let item = self.findOrCreateViewerItemController(indexPath)
                item.didFocused()

                completion?()
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
        viewerItemController.willDismiss()

        self.view.alpha = 0
        self.fadeButtons(0)
        self.buttonsAreVisible = false
        self.updateHiddenCellsUsingVisibleIndexPath(self.currentIndexPath)

        self.shouldHideStatusBar = false
        #if os(iOS)
            self.setNeedsStatusBarAppearanceUpdate()
        #endif
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
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            presentedView.frame = self.view.convertRect(selectedCellFrame, fromView: self.collectionView)
            }) { completed in
                if let existingCell = self.collectionView.cellForItemAtIndexPath(viewerItemController.indexPath!) {
                    existingCell.alpha = 1
                }

                self.headerView?.removeFromSuperview()
                self.footerView?.removeFromSuperview()
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.dismissViewControllerAnimated(false, completion: nil)
                self.controllerDelegate?.viewerControllerDidDismiss(self)

                completion?()
        }
    }

    func panAction(gesture: UIPanGestureRecognizer) {
        let controller = self.findOrCreateViewerItemController(self.currentIndexPath)
        let viewHeight = controller.imageView.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translationInView(controller.imageView)

        if gesture.state == .Began {
            self.shouldHideStatusBar = false
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            self.view.backgroundColor = UIColor.clearColor()
            self.originalDraggedCenter = controller.imageView.center
            self.isDragging = true
            self.updateHiddenCellsUsingVisibleIndexPath(self.currentIndexPath)
            controller.willDismiss()
        }

        translatedPoint = CGPoint(x: self.originalDraggedCenter.x, y: self.originalDraggedCenter.y + translatedPoint.y)
        let alphaDiff = ((translatedPoint.y - viewHalfHeight) / viewHalfHeight) * 2.5
        let isDraggedUp = translatedPoint.y < viewHalfHeight
        let alpha = isDraggedUp ? 1 + alphaDiff : 1 - alphaDiff

        controller.dimControls(alpha)
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
                    controller.dimControls(1.0)

                    if self.buttonsAreVisible == true {
                        self.fadeButtons(1)
                    }
                    }) { completed in
                        controller.didFocused()
                        self.shouldHideStatusBar = false
                        self.shouldUseLightStatusBar = true
                        #if os(iOS)
                            self.setNeedsStatusBarAppearanceUpdate()
                        #endif
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

    private func evaluateCellVisibility(collectionView collectionView: UICollectionView, currentIndexPath: NSIndexPath, upcomingIndexPath: NSIndexPath) {
        if !collectionView.indexPathsForVisibleItems().contains(upcomingIndexPath) {
            var position: UICollectionViewScrollPosition?
            if currentIndexPath.compareDirection(upcomingIndexPath) == .Forward {
                position = .Bottom
            } else if currentIndexPath.compareDirection(upcomingIndexPath) == .Backward {
                position = .Top
            }
            if let position = position {
                collectionView.scrollToItemAtIndexPath(upcomingIndexPath, atScrollPosition: position, animated: true)
            }
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

extension ViewerController: ViewerItemControllerDataSource {
    func overlayIsHidden() -> Bool {
        return !self.buttonsAreVisible
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

extension ViewerController: PaginatedScrollViewDataSource {
    func numberOfPagesInPaginatedScrollView(paginatedScrollView: PaginatedScrollView) -> Int {
        return self.controllerDataSource?.numerOfItemsInViewerController(self) ?? 0
    }

    func paginatedScrollView(paginatedScrollView: PaginatedScrollView, controllerAtIndex index: Int) -> UIViewController {
        let indexPath = NSIndexPath.indexPathForIndex(self.collectionView, index: index)!
        return self.findOrCreateViewerItemController(indexPath)
    }
}

extension ViewerController: PaginatedScrollViewDelegate {
    func paginatedScrollView(paginatedScrollView: PaginatedScrollView, didMoveToIndex index: Int) {
        let indexPath = NSIndexPath.indexPathForIndex(self.collectionView, index: index)!
        self.evaluateCellVisibility(collectionView: self.collectionView, currentIndexPath: self.currentIndexPath, upcomingIndexPath: indexPath)
        self.currentIndexPath = indexPath
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: indexPath)
        let viewerItem = self.findOrCreateViewerItemController(indexPath)
        viewerItem.didFocused()
    }

    func paginatedScrollView(paginatedScrollView: PaginatedScrollView, didMoveFromIndex index: Int) {
        let indexPath = NSIndexPath.indexPathForIndex(self.collectionView, index: index)!
        let viewerItem = self.findOrCreateViewerItemController(indexPath)
        viewerItem.willDismiss()
    }
}
