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
        let timer = Timer(timeInterval: 6, target: self, selector: #selector(goRight), userInfo: nil, repeats: true)

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

        self.loadPage(self.currentPage, animated: false, isInitial: true)
    }

    var currentController: ViewableController?

    func loadPage(_ page: Int, animated: Bool, isInitial: Bool) {
        let numPages = self.viewDataSource?.numberOfPagesInSlideshowView(self) ?? 0
        if page >= numPages || page < 0 {
            return
        }

        guard let controller = self.viewDataSource?.slideshowView(self, controllerAtIndex: page) as? ViewableController, controller.view.superview == nil else { return }
        guard let image = controller.viewable?.placeholder else { return }

        controller.view.frame = image.centeredFrame()
        self.parentController.addChildViewController(controller)
        self.addSubview(controller.view)
        controller.didMove(toParentViewController: self.parentController)

        if isInitial {
            self.currentController = controller
        } else {
            controller.view.alpha = 0
            UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: {
                self.currentController?.view.alpha = 0
                controller.view.alpha = 1
            }, completion: { isFinished in
                self.currentController?.willMove(toParentViewController: nil)
                self.currentController?.view.removeFromSuperview()
                self.currentController?.removeFromParentViewController()
                self.currentController = nil

                self.currentController = controller
                self.currentPage = page
            })
        }
    }

    func goRight() {
        let numPages = self.viewDataSource?.numberOfPagesInSlideshowView(self) ?? 0
        let newPage = self.currentPage + 1
        guard newPage <= numPages else { return }

        self.loadPage(newPage, animated: true, isInitial: false)
    }

    func startSlideshow() {
        RunLoop.current.add(self.timer, forMode: .defaultRunLoopMode)
    }

    func stopSlideshow() {
        self.timer.invalidate()
    }
}
