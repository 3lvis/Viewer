import UIKit
import Photos

class LocalCollectionController: UICollectionViewController {
    var photos = [ViewerItem]()
    var viewerController: ViewerController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    override func viewDidAppear(animated: Bool) {
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
        let bounds = UIScreen.mainScreen().bounds
        let size = (bounds.width - columns) / columns
        layout.itemSize = CGSize(width: size, height: size)
    }

    func alertControllerWithTitle(title: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))

        return alertController
    }
}

extension LocalCollectionController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        let photo = self.photos[indexPath.row]
        cell.display(photo)

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView)
        let headerView = HeaderView()
        headerView.viewDelegate = self
        self.viewerController?.headerView = headerView
        let footerView = FooterView()
        footerView.viewDelegate = self
        self.viewerController?.footerView = footerView
        self.viewerController!.controllerDataSource = self
        self.presentViewController(self.viewerController!, animated: false, completion: nil)
    }
}

extension LocalCollectionController: ViewerControllerDataSource {
    func numerOfItemsInViewerController(viewerController: ViewerController) -> Int {
        return self.photos.count
    }

    func viewerController(viewerController: ViewerController, itemAtIndexPath indexPath: NSIndexPath) -> ViewerItem {
        let item = self.photos[indexPath.row]
        self.photos[indexPath.row] = item

        return self.photos[indexPath.row]
    }
}

extension LocalCollectionController: HeaderViewDelegate {
    func headerView(headerView: HeaderView, didPressClearButton button: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(headerView: HeaderView, didPressMenuButton button: UIButton) {
        let alertController = self.alertControllerWithTitle("Options pressed")
        self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

extension LocalCollectionController: FooterViewDelegate {
    func footerView(footerView: FooterView, didPressFavoriteButton button: UIButton) {
        let alertController = self.alertControllerWithTitle("Favorite pressed")
        self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
    }

    func footerView(footerView: FooterView, didPressDeleteButton button: UIButton) {
        let alertController = self.alertControllerWithTitle("Delete pressed")
        self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
    }
}