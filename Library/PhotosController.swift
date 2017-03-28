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
    var currentIndexPath: IndexPath?
    var isPresenting = false

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

        super.init(collectionViewLayout: PhotosCollectionLayout(isGroupedByDay: true))

        self.restoresFocusAfterTransition = false
    }

    required init?(coder aDecoder: NSCoder) {
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
                    self.collectionView?.reloadItems(at: self.collectionView?.indexPathsForVisibleItems ?? [IndexPath]())
                }
            }
        case .remote:
            self.sections = Photo.constructRemoteElements()
            self.collectionView?.reloadItems(at: self.collectionView?.indexPathsForVisibleItems ?? [IndexPath]())
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        var environments = [UIFocusEnvironment]()

        if let indexPath = self.currentIndexPath {
            if let cell = self.collectionView?.cellForItem(at: indexPath) {
                environments.append(cell)
            }
        }

        return environments
    }

    func alertController(with title: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

        return alertController
    }
}

extension PhotosController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        #if os(iOS)
            let headerView = HeaderView()
            headerView.viewDelegate = self
            self.viewerController?.headerView = headerView
            let footerView = FooterView()
            footerView.viewDelegate = self
            self.viewerController?.footerView = footerView
        #endif
        self.viewerController!.delegate = self
        self.viewerController!.dataSource = self
        self.present(self.viewerController!, animated: false, completion: nil)

        self.isPresenting = true
    }

    override public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return !isPresenting
    }
}

extension PhotosController: ViewerControllerDataSource {

    func numberOfItemsInViewerController(_ viewerController: ViewerController) -> Int {
        return self.numberOfItems
    }

    func viewerController(_ viewerController: ViewerController, viewableAt indexPath: IndexPath) -> Viewable {
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

extension PhotosController: ViewerControllerDelegate {
    func viewerController(_ viewerController: ViewerController, didChangeFocusTo indexPath: IndexPath) {
        self.currentIndexPath = indexPath
    }

    func viewerControllerDidDismiss(_ viewerController: ViewerController) {
        // Required in the Apple TV to update the focus engine to the desired location.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isPresenting = false

            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    func viewerController(_ viewerController: ViewerController, didFailDisplayingViewableAt indexPath: IndexPath, error: NSError) {}
}

extension PhotosController: OptionsControllerDelegate {

    func optionsController(optionsController: OptionsController, didSelectOption option: String) {
        self.optionsController?.dismiss(animated: true) {
            self.viewerController?.dismiss(nil)
        }
    }
}

extension PhotosController: HeaderViewDelegate {

    func headerView(_ headerView: HeaderView, didPressClearButton button: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(_ headerView: HeaderView, didPressMenuButton button: UIButton) {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.optionsController = OptionsController(sourceView: button, sourceRect: rect)
        self.optionsController!.delegate = self
        self.viewerController?.present(self.optionsController!, animated: true, completion: nil)
    }
}

extension PhotosController: FooterViewDelegate {

    func footerView(_ footerView: FooterView, didPressFavoriteButton button: UIButton) {
        let alertController = self.alertController(with: "Favorite pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }

    func footerView(_ footerView: FooterView, didPressDeleteButton button: UIButton) {
        let alertController = self.alertController(with: "Delete pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}
