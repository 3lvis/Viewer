import UIKit

class CollectionController: UICollectionViewController {
    var photos = Photo.constructElements()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }
}

extension CollectionController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        if let photo = self.photos[indexPath.row] as? Photo {
            cell.text = String(photo.id)
            cell.image = photo.image
        }

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let collectionView = self.collectionView else { return }

        let viewerController = ViewerController(indexPath: indexPath, collectionView: collectionView)
        viewerController.controllerDelegate = self
        viewerController.controllerDataSource = self
        self.presentViewController(viewerController, animated: false, completion: nil)
    }
}

extension CollectionController: ViewerControllerDataSource {
    func viewerItemsForViewerController(viewerController: ViewerController) -> [ViewerItem] {
        return self.photos
    }
}

extension CollectionController: ViewerControllerDelegate {
    func viewerController(viewerController: ViewerController, didChangeIndexPath indexPath: NSIndexPath) {
    }

    func viewerControllerDidDismiss(viewerController3: ViewerController) {
    }
}
