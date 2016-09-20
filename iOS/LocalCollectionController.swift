import UIKit
import Photos

class LocalCollectionController: UICollectionViewController {
    var photos = [ViewerItem]()
    var viewerController: ViewerController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Photo.checkAuthorizationStatus { success in
            self.photos = Photo.constructLocalElements()
            self.collectionView?.reloadData()
        }
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

extension LocalCollectionController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.Identifier, for: indexPath) as! PhotoCell
        let photo = self.photos[indexPath.row]
        cell.display(photo as! CALayer)

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView)
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

extension LocalCollectionController: ViewerControllerDataSource {
    func numerOfItemsInViewerController(_ viewerController: ViewerController) -> Int {
        return self.photos.count
    }

    func viewerController(_ viewerController: ViewerController, itemAtIndexPath indexPath: IndexPath) -> ViewerItem {
        var item = self.photos[indexPath.row]
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? PhotoCell, let placeholder = cell.imageView.image {
            item.placeholder = placeholder
        }
        self.photos[indexPath.row] = item

        return self.photos[indexPath.row]
    }
}

extension LocalCollectionController: HeaderViewDelegate {
    func headerView(_ headerView: HeaderView, didPressClearButton button: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(_ headerView: HeaderView, didPressMenuButton button: UIButton) {
        let alertController = self.alertController(with: "Options pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}

extension LocalCollectionController: FooterViewDelegate {
    func footerView(_ footerView: FooterView, didPressFavoriteButton button: UIButton) {
        let alertController = self.alertController(with: "Favorite pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }

    func footerView(_ footerView: FooterView, didPressDeleteButton button: UIButton) {
        let alertController = self.alertController(with: "Delete pressed")
        self.viewerController?.present(alertController, animated: true, completion: nil)
    }
}
