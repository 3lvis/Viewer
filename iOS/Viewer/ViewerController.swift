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
    var originalDraggedCenter = CGPointZero
    var isDragging = false
    var lastAlpha = CGFloat(0)
    var currentIndex = 0

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

    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: "pan:")
        gesture.delegate = self

        return gesture
    }()

    // MARK: View Lifecycle

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.present(self.indexPath)
    }

    func presentedViewCopy() -> UIImageView {
        let presentedView = UIImageView()
        presentedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        presentedView.contentMode = .ScaleAspectFill
        presentedView.clipsToBounds = true
        return presentedView
    }

    func present(indexPath: NSIndexPath) {
        guard let window = UIApplication.sharedApplication().delegate?.window?!, selectedCell = self.collectionView.cellForItemAtIndexPath(indexPath), items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError("Data source not implemented") }

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

    func dismiss(viewerItemController: ViewerItemController, completion: (() -> ())?) {
        let indexPath = NSIndexPath(forRow: viewerItemController.index, inSection: 0)
        guard let window = UIApplication.sharedApplication().delegate?.window?!, selectedCellFrame = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)?.frame, items = self.controllerDataSource?.viewerItemsForViewerController(self), image = items[indexPath.row].image else { fatalError() }

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

    func pan(gesture: UIPanGestureRecognizer) {
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

        self.currentIndex = index


        return viewerItemController
    }
}

extension ViewerController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController {
            viewerItemController.imageView.removeGestureRecognizer(self.panGestureRecognizer)

            let index = viewerItemController.index
            if index > 0 {
                let newIndex = index - 1
                self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: newIndex, inSection: 0))
                let controller = self.findOrCreateViewerItemController(newIndex)
                controller.imageView.addGestureRecognizer(self.panGestureRecognizer)

                return controller
            }
        }

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewerItemController = viewController as? ViewerItemController, viewerItems = self.controllerDataSource?.viewerItemsForViewerController(self) {
            viewerItemController.imageView.removeGestureRecognizer(self.panGestureRecognizer)

            let index = viewerItemController.index
            if index < viewerItems.count - 1 {
                let newIndex = index + 1
                self.controllerDelegate?.viewerController(self, didChangeIndexPath: NSIndexPath(forRow: newIndex, inSection: 0))
                let controller = self.findOrCreateViewerItemController(newIndex)
                controller.imageView.addGestureRecognizer(self.panGestureRecognizer)

                return controller
            }
        }

        return nil
    }
}

extension ViewerController: ViewerItemControllerDelegate {
    func viewerItemControllerDidTapItem(viewerItemController: ViewerItemController, completion: (() -> ())?) {
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
