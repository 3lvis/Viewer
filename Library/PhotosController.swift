import UIKit

enum DataSourceType {
    case local
    case remote
}

class PhotosController: UICollectionViewController {
    var dataSourceType: DataSourceType
    var viewerController: ViewerController?
    var optionsController: OptionsController?
    var numberOfItems = 0
    var sections = [Section]() {
        didSet {
            var count = 0
            for i in 0 ..< self.sections.count {
                let section = self.sections[i]
                count += section.photos.count
            }
            self.numberOfItems = count
        }
    }

    init(dataSourceType: DataSourceType) {
        self.dataSourceType = dataSourceType

        super.init(collectionViewLayout: PhotosCollectionLayout())
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.backgroundColor = .white
        self.collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)

        switch self.dataSourceType {
        case .local:
            Photo.checkAuthorizationStatus { success in
                if success {
                    self.sections = Photo.constructLocalElements()
                    self.collectionView?.reloadData()
                }
            }
        case .remote:
            self.sections = Photo.constructRemoteElements()
            self.collectionView?.reloadData()
        }
    }

    #if os(tvOS)
        override var preferredFocusEnvironments: [UIFocusEnvironment] {
            var environments = [UIFocusEnvironment]()

            if let indexPath = self.viewerController?.currentIndexPath {
                if let cell = self.collectionView?.cellForItem(at: indexPath) {
                    environments.append(cell)
                }
            }

            return environments
        }
    #endif

    func alertController(with title: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

        return alertController
    }
}

extension PhotosController {

    override func numberOfSections(in _: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = self.sections[section]

        return section.photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.Identifier, for: indexPath) as! PhotoCell
        let section = self.sections[indexPath.section]
        let photo = section.photos[indexPath.row]
        cell.photo = photo
        cell.photo?.placeholder = cell.imageView.image ?? UIImage()

        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView)
        self.viewerController!.dataSource = self

        #if os(iOS)
            let headerView = HeaderView()
            headerView.viewDelegate = self
            self.viewerController?.headerView = headerView
            let footerView = FooterView()
            footerView.viewDelegate = self
            self.viewerController?.footerView = footerView
        #else
            self.viewerController!.delegate = self
        #endif

        self.present(self.viewerController!, animated: false, completion: nil)
    }

    #if os(tvOS)
        public override func collectionView(_: UICollectionView, canFocusItemAt _: IndexPath) -> Bool {
            let isViewerVisible = self.viewerController?.isPresented ?? false
            let shouldFocusCells = !isViewerVisible

            return shouldFocusCells
        }
    #endif
}

extension PhotosController: ViewerControllerDataSource {

    func numberOfItemsInViewerController(_: ViewerController) -> Int {
        return self.numberOfItems
    }

    func viewerController(_: ViewerController, viewableAt indexPath: IndexPath) -> Viewable {
        var section = self.sections[indexPath.section]
        var viewable = section.photos[indexPath.row]
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? PhotoCell, let placeholder = cell.imageView.image {
            viewable.placeholder = placeholder
        }
        section.photos[indexPath.row] = viewable
        self.sections[indexPath.section] = section

        return viewable
    }
}

#if os(tvOS)
    extension PhotosController: ViewerControllerDelegate {
        func viewerController(_: ViewerController, didChangeFocusTo _: IndexPath) {}

        func viewerControllerDidDismiss(_: ViewerController) {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }

        func viewerController(_: ViewerController, didFailDisplayingViewableAt _: IndexPath, error _: NSError) {}
    }
#endif

extension PhotosController: OptionsControllerDelegate {

    func optionsController(optionsController _: OptionsController, didSelectOption _: String) {
        self.optionsController?.dismiss(animated: true) {
            self.viewerController?.dismiss(nil)
        }
    }
}

extension PhotosController: HeaderViewDelegate {

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

extension PhotosController: FooterViewDelegate {

    func footerView(_: FooterView, didPressFavoriteButton _: UIButton) {
        let alertController = self.alertController(with: "Favorite pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }

    func footerView(_: FooterView, didPressDeleteButton _: UIButton) {
        let alertController = self.alertController(with: "Delete pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}
