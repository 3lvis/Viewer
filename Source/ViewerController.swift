import UIKit
import CoreData

/**
 The ViewerController takes care of displaying the user's photos/videos in full-screen.

 You can swipe right or left to navigate between photos.
 */

public protocol ViewerControllerDataSource: class {
    func numberOfItemsInViewerController(_ viewerController: ViewerController) -> Int
    func viewerController(_ viewerController: ViewerController, itemAtIndexPath indexPath: IndexPath) -> Viewable
}

public protocol ViewerControllerDelegate: class {
    /**
     When the ViewerController jumps between photos it triggers a call to the viewerController:didChangeIndexPath: delegate
     */
    func viewerController(_ viewerController: ViewerController, didChangeIndexPath indexPath: IndexPath)

    /**
     When the ViewerController is dismissed it triggers a call to the viewerControllerDidDismiss: delegate
     */
    func viewerControllerDidDismiss(_ viewerController: ViewerController)
}

public class ViewerController: UIViewController {
    fileprivate static let HeaderHeight = CGFloat(64)
    fileprivate static let FooterHeight = CGFloat(50)
    fileprivate static let DraggingMargin = CGFloat(60)

    public init(initialIndexPath: IndexPath, collectionView: UICollectionView) {
        self.initialIndexPath = initialIndexPath
        self.currentIndexPath = initialIndexPath
        self.collectionView = collectionView

        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = .clear
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.modalPresentationStyle = .overCurrentContext
        #if os(iOS)
            self.modalPresentationCapturesStatusBarAppearance = true
        #endif
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public weak var controllerDelegate: ViewerControllerDelegate?
    public weak var controllerDataSource: ViewerControllerDataSource?

    /**
     Flag that tells the viewer controller to autoplay videos on focus
     */
    public var autoplayVideos: Bool = false

    /**
     Cache for the reused ViewableControllers
     */
    fileprivate let viewableControllerCache = NSCache<NSString, ViewableController>()

    /**
     Temporary variable used to present the initial controller on viewDidAppear
     */
    fileprivate var initialIndexPath: IndexPath

    /**
     The UICollectionView to be used when dismissing and presenting elements
     */
    fileprivate unowned var collectionView: UICollectionView

    /**
     CGPoint used for diffing the panning on an image
     */
    fileprivate var originalDraggedCenter = CGPoint.zero

    /**
     Used for doing a different animation when dismissing in the middle of a dragging gesture
     */
    fileprivate var isDragging = false

    /**
     Keeps track of where the status bar should be hidden or not
     */
    fileprivate var shouldHideStatusBar = false

    /**
     Keeps track of where the status bar should be light or not
     */
    fileprivate var shouldUseLightStatusBar = true

    /**
     Critical button visibility state tracker, it's used to force the buttons to keep being hidden when they are toggled
     */
    fileprivate var buttonsAreVisible = false

    /**
     Tracks the index for the current viewer item controller
     */
    fileprivate var currentIndexPath: IndexPath

    /**
     A helper to prevent the paginated scroll view to be set up twice when is presented
     */
    fileprivate var presented = false

    fileprivate lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        view.alpha = 0
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return view
    }()

    public var headerView: UIView?

    public var footerView: UIView?

    lazy var scrollView: PaginatedScrollView = {
        let view = PaginatedScrollView(frame: self.view.frame, parentController: self, initialPage: self.initialIndexPath.totalRow(self.collectionView))
        view.viewDataSource = self
        view.viewDelegate = self
        view.backgroundColor = .clear

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
            if !self.collectionView.indexPathsForVisibleItems.contains(self.currentIndexPath) {
                self.collectionView.scrollToItem(at: self.currentIndexPath, at: .bottom, animated: true)
            }
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.present(with: self.initialIndexPath, completion: nil)
    }
}

extension ViewerController {
    #if os(iOS)
    public override var prefersStatusBarHidden : Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        if UIInterfaceOrientationIsLandscape(orientation) {
            return true
        }

        return self.shouldHideStatusBar
    }

    public override var preferredStatusBarStyle : UIStatusBarStyle {
        if self.shouldUseLightStatusBar {
            return .lightContent
        } else {
            return self.presentingViewController?.preferredStatusBarStyle ?? .default
        }
    }
    #endif

    private func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedView.contentMode = .scaleAspectFill
        presentedView.clipsToBounds = true

        return presentedView
    }

    fileprivate func findOrCreateViewableController(_ indexPath: IndexPath) -> ViewableController {
        let viewable = self.controllerDataSource!.viewerController(self, itemAtIndexPath: indexPath)
        var viewableController: ViewableController

        if let cachedController = self.viewableControllerCache.object(forKey: viewable.id as NSString) {
            viewableController = cachedController
        } else {
            viewableController = ViewableController()
            viewableController.controllerDelegate = self
            viewableController.controllerDataSource = self

            let gesture = UIPanGestureRecognizer(target: self, action: #selector(ViewerController.panAction(_:)))
            gesture.delegate = self
            viewableController.imageView.addGestureRecognizer(gesture)

            self.viewableControllerCache.setObject(viewableController, forKey: viewable.id as NSString)
        }

        viewableController.viewable = viewable
        viewableController.indexPath = indexPath

        return viewableController
    }

    fileprivate func toggleButtons(_ shouldShow: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            self.headerView?.alpha = shouldShow ? 1 : 0
            self.footerView?.alpha = shouldShow ? 1 : 0
        }) 
    }

    private func fadeButtons(_ alpha: CGFloat) {
        self.headerView?.alpha = alpha
        self.footerView?.alpha = alpha
    }

    fileprivate func present(with indexPath: IndexPath, completion: (() -> Void)?) {
        guard let selectedCell = self.collectionView.cellForItem(at: indexPath) else { fatalError("Data source not implemented") }

        let viewable = self.controllerDataSource!.viewerController(self, itemAtIndexPath: indexPath)
        let image = viewable.placeholder
        selectedCell.alpha = 0

        let presentedView = self.presentedViewCopy()
        presentedView.frame = self.view.convert(selectedCell.frame, from: self.collectionView)
        presentedView.image = image

        self.view.addSubview(self.overlayView)
        self.view.addSubview(presentedView)

        if let headerView = self.headerView {
            let bounds = UIScreen.main.bounds
            headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: ViewerController.HeaderHeight)
            headerView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin, .flexibleWidth]
            headerView.alpha = 0
            self.view.addSubview(headerView)
        }

        if let footerView = self.footerView {
            let bounds = UIScreen.main.bounds
            footerView.frame = CGRect(x: 0, y: bounds.size.height - ViewerController.FooterHeight, width: bounds.width, height: ViewerController.FooterHeight)
            footerView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth]
            footerView.alpha = 0
            self.view.addSubview(footerView)
        }

        let centeredImageFrame = image.centeredFrame()
        UIView.animate(withDuration: 0.25, animations: {
            self.presentingViewController?.tabBarController?.tabBar.alpha = 0
            self.overlayView.alpha = 1.0
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            presentedView.frame = centeredImageFrame
            }, completion: { completed in
                self.toggleButtons(true)
                self.buttonsAreVisible = true
                self.currentIndexPath = indexPath
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.view.backgroundColor = .black
                self.presented = true
                let item = self.findOrCreateViewableController(indexPath)
                item.didFocus()

                completion?()
        }) 
    }

    public func dismiss(_ completion: (() -> Void)?) {
        let controller = self.findOrCreateViewableController(self.currentIndexPath)
        self.dismiss(controller, completion: completion)
    }

    private func dismiss(_ viewableController: ViewableController, completion: (() -> Void)?) {
        guard let selectedCellFrame = self.collectionView.layoutAttributesForItem(at: viewableController.indexPath!)?.frame else { fatalError() }

        let viewable = self.controllerDataSource!.viewerController(self, itemAtIndexPath: viewableController.indexPath!)
        let image = viewable.placeholder
        viewableController.imageView.alpha = 0
        viewableController.view.backgroundColor = .clear
        viewableController.willDismiss()

        self.view.alpha = 0
        self.fadeButtons(0)
        self.buttonsAreVisible = false
        self.updateHiddenCellsUsingVisibleIndexPath(self.currentIndexPath)

        self.shouldHideStatusBar = false
        #if os(iOS)
            self.setNeedsStatusBarAppearanceUpdate()
        #endif
        self.overlayView.alpha = self.isDragging ? viewableController.view.backgroundColor!.cgColor.alpha : 1.0
        self.overlayView.frame = UIScreen.main.bounds

        let presentedView = self.presentedViewCopy()
        presentedView.frame = image.centeredFrame()
        presentedView.image = image
        if self.isDragging {
            presentedView.center = viewableController.imageView.center
        }

        let window = self.applicationWindow()
        window.addSubview(self.overlayView)
        window.addSubview(presentedView)
        self.shouldUseLightStatusBar = false

        UIView.animate(withDuration: 0.30, animations: {
            self.presentingViewController?.tabBarController?.tabBar.alpha = 1
            self.overlayView.alpha = 0.0
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            presentedView.frame = self.view.convert(selectedCellFrame, from: self.collectionView)
            }, completion: { completed in
                if let existingCell = self.collectionView.cellForItem(at: viewableController.indexPath!) {
                    existingCell.alpha = 1
                }

                self.headerView?.removeFromSuperview()
                self.footerView?.removeFromSuperview()
                presentedView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.dismiss(animated: false, completion: nil)
                self.controllerDelegate?.viewerControllerDidDismiss(self)

                completion?()
        }) 
    }

    func panAction(_ gesture: UIPanGestureRecognizer) {
        let controller = self.findOrCreateViewableController(self.currentIndexPath)
        let viewHeight = controller.imageView.frame.size.height
        let viewHalfHeight = viewHeight / 2
        var translatedPoint = gesture.translation(in: controller.imageView)

        if gesture.state == .began {
            self.shouldHideStatusBar = false
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
            #endif
            self.view.backgroundColor = .clear
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
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(alpha)

        if self.buttonsAreVisible {
            self.fadeButtons(alpha)
        }

        if gesture.state == .ended {
            let centerAboveDraggingArea = controller.imageView.center.y < viewHalfHeight - ViewerController.DraggingMargin
            let centerBellowDraggingArea = controller.imageView.center.y > viewHalfHeight + ViewerController.DraggingMargin
            if centerAboveDraggingArea || centerBellowDraggingArea {
                self.dismiss(controller, completion: nil)
            } else {
                self.isDragging = false
                UIView.animate(withDuration: 0.20, animations: {
                    controller.imageView.center = self.originalDraggedCenter
                    controller.view.backgroundColor = .black
                    controller.dimControls(1.0)

                    if self.buttonsAreVisible {
                        self.fadeButtons(1)
                    }

                    self.shouldHideStatusBar = !self.buttonsAreVisible
                    self.shouldUseLightStatusBar = true

                    #if os(iOS)
                        self.setNeedsStatusBarAppearanceUpdate()
                    #endif
                    }, completion: { completed in
                        controller.didFocus()
                        self.view.backgroundColor = .black
                }) 
            }
        }
    }

    private func centerElementIfNotVisible(_ indexPath: IndexPath) {
        if !self.collectionView.indexPathsForVisibleItems.contains(indexPath) {
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }

    private func updateHiddenCellsUsingVisibleIndexPath(_ visibleIndexPath: IndexPath) {
        for indexPath in self.collectionView.indexPathsForVisibleItems {
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                cell.alpha = indexPath == visibleIndexPath ? 0 : 1
            }
        }
    }

    fileprivate func evaluateCellVisibility(collectionView: UICollectionView, currentIndexPath: IndexPath, upcomingIndexPath: IndexPath) {
        if !collectionView.indexPathsForVisibleItems.contains(upcomingIndexPath) {
            var position: UICollectionViewScrollPosition?
            if currentIndexPath.compareDirection(upcomingIndexPath) == .forward {
                position = .bottom
            } else if currentIndexPath.compareDirection(upcomingIndexPath) == .backward {
                position = .top
            }
            if let position = position {
                collectionView.scrollToItem(at: upcomingIndexPath, at: position, animated: true)
            }
        }
    }
}

extension ViewerController: ViewableControllerDelegate {
    func viewableControllerDidTapItem(_ viewableController: ViewableController, completion: (() -> Void)?) {
        self.shouldHideStatusBar = !self.shouldHideStatusBar
        self.buttonsAreVisible = !self.buttonsAreVisible
        self.toggleButtons(self.buttonsAreVisible)
    }
}

extension ViewerController: ViewableControllerDataSource {
    func isViewableControllerOverlayHidden(_ viewableController: ViewableController) -> Bool {
        return !self.buttonsAreVisible
    }

    func viewableControllerIsFocused(_ viewableController: ViewableController) -> Bool {
        let focusedViewableController = self.findOrCreateViewableController(self.currentIndexPath)

        return viewableController == focusedViewableController
    }

    func viewableControllerShouldAutoplayVideo(_ viewableController: ViewableController) -> Bool {
        return self.autoplayVideos
    }
}

extension ViewerController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view!)
            let allowOnlyVerticalScrolls = fabs(velocity.y) > fabs(velocity.x)
            
            return allowOnlyVerticalScrolls
        }
        
        return true
    }
}

extension ViewerController: PaginatedScrollViewDataSource {
    func numberOfPagesInPaginatedScrollView(_ paginatedScrollView: PaginatedScrollView) -> Int {
        return self.controllerDataSource?.numberOfItemsInViewerController(self) ?? 0
    }

    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, controllerAtIndex index: Int) -> UIViewController {
        let indexPath = IndexPath.indexPathForIndex(self.collectionView, index: index)!

        return self.findOrCreateViewableController(indexPath)
    }
}

extension ViewerController: PaginatedScrollViewDelegate {
    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, didMoveToIndex index: Int) {
        let indexPath = IndexPath.indexPathForIndex(self.collectionView, index: index)!
        self.evaluateCellVisibility(collectionView: self.collectionView, currentIndexPath: self.currentIndexPath, upcomingIndexPath: indexPath)
        self.currentIndexPath = indexPath
        self.controllerDelegate?.viewerController(self, didChangeIndexPath: indexPath)
        let viewableController = self.findOrCreateViewableController(indexPath)
        viewableController.didFocus()
    }

    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, didMoveFromIndex index: Int) {
        let indexPath = IndexPath.indexPathForIndex(self.collectionView, index: index)!
        let viewableController = self.findOrCreateViewableController(indexPath)
        viewableController.willDismiss()
    }
}
