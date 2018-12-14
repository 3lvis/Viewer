import UIKit

class PhotoController: UIViewController {
    var optionsController: OptionsController?
    var viewerController: ViewerController?
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false

        #if os(iOS)
        view.clipsToBounds = true
        #else
        view.clipsToBounds = false
        view.adjustsImageWhenAncestorFocused = true
        #endif

        return view
    }()

    var photo: Photo {
        let photo = Photo(id: "a")
        photo.placeholder = UIImage(named: "0.jpg")!
        return photo
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        imageView.image = photo.placeholder
    }

    func alertController(with title: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

        return alertController
    }
}

extension PhotoController {
    func show() {
        self.viewerController = ViewerController(initialIndexPath: IndexPath(row: 0, section: 0), collectionView: UICollectionView())
        self.viewerController!.dataSource = self
        self.viewerController!.delegate = self

        #if os(iOS)
        let headerView = HeaderView()
        headerView.viewDelegate = self
        self.viewerController?.headerView = headerView
        let footerView = FooterView()
        footerView.viewDelegate = self
        self.viewerController?.footerView = footerView
        #endif

        self.present(self.viewerController!, animated: false, completion: nil)
    }
}

extension PhotoController: OptionsControllerDelegate {

    func optionsController(optionsController _: OptionsController, didSelectOption _: String) {
        self.optionsController?.dismiss(animated: true) {
            self.viewerController?.dismiss(nil)
        }
    }
}

extension PhotoController: ViewerControllerDataSource {

    func numberOfItemsInViewerController(_: ViewerController) -> Int {
        return 1
    }

    func viewerController(_: ViewerController, viewableAt indexPath: IndexPath) -> Viewable {
        let viewable = Photo(id: "")
        viewable.placeholder = UIImage()
        return viewable
    }
}

extension PhotoController: ViewerControllerDelegate {
    func viewerController(_: ViewerController, didChangeFocusTo _: IndexPath) {}

    func viewerControllerDidDismiss(_: ViewerController) {
        #if os(tvOS)
        // Used to refocus after swiping a few items in fullscreen.
        self.setNeedsFocusUpdate()
        self.updateFocusIfNeeded()
        #endif
    }

    func viewerController(_: ViewerController, didFailDisplayingViewableAt _: IndexPath, error _: NSError) {

    }

    func viewerController(_ viewerController: ViewerController, didLongPressViewableAt indexPath: IndexPath) {
        print("didLongPressViewableAt: \(indexPath)")
    }
}

extension PhotoController: HeaderViewDelegate {

    func headerView(_: HeaderView, didPressClearButton _: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(_: HeaderView, didPressMenuButton button: UIButton) {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.optionsController = OptionsController(sourceView: button, sourceRect: rect)
        self.optionsController!.delegate = self
        self.viewerController?.present(self.optionsController!, animated: true, completion: nil)
    }
}

extension PhotoController: FooterViewDelegate {

    func footerView(_: FooterView, didPressFavoriteButton _: UIButton) {
        let alertController = self.alertController(with: "Favorite pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }

    func footerView(_: FooterView, didPressDeleteButton _: UIButton) {
        let alertController = self.alertController(with: "Delete pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}
