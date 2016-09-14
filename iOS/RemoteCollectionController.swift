import UIKit

class RemoteCollectionController: UICollectionViewController {
    var sections = Photo.constructRemoteElements()
    var viewerController: ViewerController?
    var optionsController: OptionsController?
    var numberOfItems = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)

        var count = 0
        for i in 0..<self.sections.count {
            let photos = self.sections[i]
            count += photos.count
        }
        self.numberOfItems = count
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let layout = self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let columns = CGFloat(4)
        let bounds = UIScreen.main.bounds
        let size = (bounds.width - columns) / columns
        layout.itemSize = CGSize(width: size, height: size)
    }

    func alertController(with title: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

        return alertController
    }
}

extension RemoteCollectionController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = self.sections[section]

        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.Identifier, for: indexPath as IndexPath) as! PhotoCell
        let photos = self.sections[indexPath.section]
        let photo = photos[indexPath.row]
        cell.display(photo as! CALayer)

        return cell
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.viewerController = ViewerController(initialIndexPath: indexPath as IndexPath, collectionView: collectionView)
        let headerView = HeaderView()
        headerView.viewDelegate = self
        self.viewerController?.headerView = headerView
        let footerView = FooterView()
        footerView.viewDelegate = self
        self.viewerController?.footerView = footerView
        self.viewerController!.controllerDataSource = self
        self.present(self.viewerController!, animated: false, completion: nil)
    }
}

extension RemoteCollectionController: ViewerControllerDataSource {
    func numerOfItemsInViewerController(_ viewerController: ViewerController) -> Int {
        return self.numberOfItems
    }

func viewerController(_ viewerController: ViewerController, itemAtIndexPath indexPath: IndexPath) -> ViewerItem {
        let photos = self.sections[indexPath.section]
        let viewerItem = photos[indexPath.row]

        return viewerItem
    }
}

extension RemoteCollectionController: OptionsControllerDelegate {
    func optionsController(optionsController: OptionsController, didSelectOption option: String) {
        self.optionsController?.dismiss(animated: true) {
            self.viewerController?.dismiss(nil)
        }
    }
}

extension RemoteCollectionController: HeaderViewDelegate {
    func headerView(_ headerView: HeaderView, didPressClearButton button: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(_ headerView: HeaderView, didPressMenuButton button: UIButton) {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.optionsController = OptionsController(sourceView: button, sourceRect: rect)
        self.optionsController!.controllerDelegate = self
        self.viewerController?.present(self.optionsController!, animated: true, completion: nil)
    }
}

extension RemoteCollectionController: FooterViewDelegate {
    func footerView(_ footerView: FooterView, didPressFavoriteButton button: UIButton) {
        let alertController = self.alertController(with: "Favorite pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }

    func footerView(_ footerView: FooterView, didPressDeleteButton button: UIButton) {
        let alertController = self.alertController(with: "Delete pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}
