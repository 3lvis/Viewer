import UIKit

protocol SlideshowViewDataSource: class {
    func numberOfPagesInSlideshowView(_ slideshowView: SlideshowView) -> Int
    func slideshowView(_ slideshowView: SlideshowView, controllerAtIndex index: Int) -> UIViewController
}

protocol SlideshowViewDelegate: class {
    func slideshowView(_ slideshowView: SlideshowView, didMoveToIndex index: Int)
    func slideshowView(_ slideshowView: SlideshowView, didMoveFromIndex index: Int)
}

class SlideshowView: UIView {
    weak var viewDataSource: SlideshowViewDataSource?
    weak var viewDelegate: SlideshowViewDelegate?
    unowned var parentController: UIViewController
    var currentPage: Int

    lazy var timer: Timer = {
        let timer = Timer(timeInterval: 4, target: self, selector: #selector(goRight), userInfo: nil, repeats: true)

        return timer
    }()

    init(frame: CGRect, parentController: UIViewController, initialPage: Int) {
        self.parentController = parentController
        self.currentPage = initialPage

        super.init(frame: frame)

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        self.subviews.forEach { view in
            view.removeFromSuperview()
        }

        self.loadPage(self.currentPage, animated: false)
    }

    func loadPage(_ page: Int, animated: Bool) {
        let numPages = self.viewDataSource?.numberOfPagesInSlideshowView(self) ?? 0
        if page >= numPages || page < 0 {
            return
        }

        if let controller = self.viewDataSource?.slideshowView(self, controllerAtIndex: page) as? ViewableController, controller.view.superview == nil {
            guard let image = controller.viewable?.placeholder else { return }

            controller.view.frame = image.centeredFrame()
            self.parentController.addChildViewController(controller)
            self.addSubview(controller.view)
            controller.didMove(toParentViewController: self.parentController)
        }
    }

//    func loadScrollViewWithPage(_ page: Int) {
//        let numPages = self.viewDataSource?.numberOfPagesInSlideshowView(self) ?? 0
//        if page >= numPages || page < 0 {
//            return
//        }
//
//        if let controller = self.viewDataSource?.slideshowView(self, controllerAtIndex: page), controller.view.superview == nil {
//            var frame = self.frame
//            frame.origin.x = frame.size.width * CGFloat(page)
//            frame.origin.y = 0
//            controller.view.frame = frame
//
//            self.parentController.addChildViewController(controller)
//            self.addSubview(controller.view)
//            controller.didMove(toParentViewController: self.parentController)
//        }
//    }

//    func gotoPage(_ page: Int, animated: Bool) {
//        if animated {
//            if let controller = self.viewDataSource?.slideshowView(self, controllerAtIndex: page) as? ViewableController {
//                if controller.viewable?.type == .video {
//                    self.gotoPage(page + 1, animated: animated)
//                    return
//                }
//            }
//        }
//
//        self.loadScrollViewWithPage(page - 1)
//        self.loadScrollViewWithPage(page)
//        self.loadScrollViewWithPage(page + 1)
//
//        var bounds = self.bounds
//        bounds.origin.x = bounds.size.width * CGFloat(page)
//        bounds.origin.y = 0
//
//        self.alpha = 0
//        let duration = animated ? 0.3 : 0
//        UIView.animate(withDuration: duration) {
//            self.alpha = 1
//        }
//    }

    func goRight() {
        let numPages = self.viewDataSource?.numberOfPagesInSlideshowView(self) ?? 0
        let newPage = self.currentPage + 1
        guard newPage <= numPages else { return }

//        self.gotoPage(newPage, animated: true)
    }

    func startSlideshow() {
        RunLoop.current.add(self.timer, forMode: .defaultRunLoopMode)
    }

    func stopSlideshow() {
        self.timer.invalidate()
    }
}
