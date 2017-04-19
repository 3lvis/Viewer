import UIKit

class SlideshowView: UIView, ViewableControllerContainer {
    fileprivate static let fadeDuration: Double = 1
    fileprivate static let transitionToNextDuration: Double = 6

    weak var dataSource: ViewableControllerContainerDataSource?
    weak var delegate: ViewableControllerContainerDelegate?
    fileprivate unowned var parentController: UIViewController
    fileprivate var currentPage: Int
    fileprivate var currentController: ViewableController?

    fileprivate lazy var timer: Timer = {
        let timer = Timer(timeInterval: SlideshowView.transitionToNextDuration, target: self, selector: #selector(loadNext), userInfo: nil, repeats: true)

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

    fileprivate func loadPage(_ page: Int, animated: Bool, isInitial: Bool) {
        let numPages = self.dataSource?.numberOfPagesInViewableControllerContainer(self) ?? 0
        if page >= numPages || page < 0 {
            return
        }

        guard let controller = self.dataSource?.viewableControllerContainer(self, controllerAtIndex: page) as? ViewableController else { return }
        guard let image = controller.viewable?.placeholder else { return }

        controller.view.frame = image.centeredFrame()
        self.parentController.addChildViewController(controller)
        self.addSubview(controller.view)
        controller.didMove(toParentViewController: self.parentController)

        if isInitial {
            self.currentController = controller
        } else {
            self.delegate?.viewableControllerContainer(self, didMoveFromIndex: self.currentPage)
            self.delegate?.viewableControllerContainer(self, didMoveToIndex: page)

            controller.view.alpha = 0
            UIView.animate(withDuration: SlideshowView.fadeDuration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: {
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

    func loadNext() {
        let numPages = self.dataSource?.numberOfPagesInViewableControllerContainer(self) ?? 0
        var newPage = self.currentPage + 1

        guard newPage <= numPages else { return }

        let hasReachedEnd = newPage == numPages
        if hasReachedEnd {
            newPage = 0
        }

        self.loadPage(newPage, animated: true, isInitial: false)
    }

    func start() {
        RunLoop.current.add(self.timer, forMode: .defaultRunLoopMode)
    }

    func stop() {
        self.timer.invalidate()
    }
}
