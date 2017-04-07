import UIKit

protocol PaginatedScrollViewDataSource: class {
    func numberOfPagesInPaginatedScrollView(_ paginatedScrollView: PaginatedScrollView) -> Int
    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, controllerAtIndex index: Int) -> UIViewController
}

protocol PaginatedScrollViewDelegate: class {
    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, didMoveToIndex index: Int)
    func paginatedScrollView(_ paginatedScrollView: PaginatedScrollView, didMoveFromIndex index: Int)
}

class PaginatedScrollView: UIScrollView {
    weak var viewDataSource: PaginatedScrollViewDataSource?
    weak var viewDelegate: PaginatedScrollViewDelegate?
    unowned var parentController: UIViewController
    var currentPage: Int

    init(frame: CGRect, parentController: UIViewController, initialPage: Int) {
        self.parentController = parentController
        self.currentPage = initialPage

        super.init(frame: frame)

        #if os(iOS)
            self.isPagingEnabled = true
            self.scrollsToTop = false
        #endif
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.delegate = self
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.decelerationRate = UIScrollViewDecelerationRateFast
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        self.subviews.forEach { view in
            view.removeFromSuperview()
        }

        let numPages = self.viewDataSource?.numberOfPagesInPaginatedScrollView(self) ?? 0
        self.contentSize = CGSize(width: self.frame.size.width * CGFloat(numPages), height: self.frame.size.height)

        self.loadScrollViewWithPage(self.currentPage - 1)
        self.loadScrollViewWithPage(self.currentPage)
        self.loadScrollViewWithPage(self.currentPage + 1)
        self.gotoPage(self.currentPage, animated: false, isSlideshow: false)
    }

    func loadScrollViewWithPage(_ page: Int) {
        let numPages = self.viewDataSource?.numberOfPagesInPaginatedScrollView(self) ?? 0
        if page >= numPages || page < 0 {
            return
        }

        if let controller = self.viewDataSource?.paginatedScrollView(self, controllerAtIndex: page), controller.view.superview == nil {
            var frame = self.frame
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0
            controller.view.frame = frame

            self.parentController.addChildViewController(controller)
            self.addSubview(controller.view)
            controller.didMove(toParentViewController: self.parentController)
        }
    }

    func gotoPage(_ page: Int, animated: Bool, isSlideshow: Bool) {
        self.loadScrollViewWithPage(page - 1)
        self.loadScrollViewWithPage(page)
        self.loadScrollViewWithPage(page + 1)

        var bounds = self.bounds
        bounds.origin.x = bounds.size.width * CGFloat(page)
        bounds.origin.y = 0

        if isSlideshow {
            self.shoudEvaluate = true

            self.alpha = 0
            self.scrollRectToVisible(bounds, animated: false)
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1

                self.shoudEvaluate = false
            }
        } else {
            self.scrollRectToVisible(bounds, animated: animated)
        }
    }

    var shoudEvaluate = false

    func goRight(isSlideshow: Bool) {
        let numPages = self.viewDataSource?.numberOfPagesInPaginatedScrollView(self) ?? 0
        let newPage = self.currentPage + 1
        guard newPage <= numPages else { return }

        self.gotoPage(newPage, animated: true, isSlideshow: isSlideshow)
    }

    func goLeft() {
        let newPage = self.currentPage - 1
        guard newPage >= 0 else { return }

        self.gotoPage(newPage, animated: true, isSlideshow: false)
    }

    lazy var timer: Timer = {
        let timer = Timer(timeInterval: 4, target: self, selector: #selector(fadeToNext), userInfo: nil, repeats: true)

        return timer
    }()

    func fadeToNext() {
        self.goRight(isSlideshow: true)
    }

    func startSlideshow() {
        RunLoop.current.add(self.timer, forMode: .defaultRunLoopMode)
    }

    func stopSlideshow() {
        self.timer.invalidate()
    }
}

extension PaginatedScrollView: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_: UIScrollView) {
        self.shoudEvaluate = true
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        self.shoudEvaluate = false
    }

    func scrollViewDidScroll(_: UIScrollView) {
        if self.shoudEvaluate {
            let pageWidth = self.frame.size.width
            let page = Int(floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
            if page != self.currentPage {
                self.viewDelegate?.paginatedScrollView(self, didMoveToIndex: page)
                self.viewDelegate?.paginatedScrollView(self, didMoveFromIndex: self.currentPage)
            }
            self.currentPage = page

            self.loadScrollViewWithPage(page - 1)
            self.loadScrollViewWithPage(page)
            self.loadScrollViewWithPage(page + 1)
        }
    }
}
