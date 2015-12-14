import UIKit

class CollectionController: UICollectionViewController {
    var photos = Photo.constructElements()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let layout = self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout

        let bounds = UIScreen.mainScreen().bounds
        let size = (bounds.width - 4) / 4
        layout.itemSize = CGSize(width: size, height: size)
    }
}

extension CollectionController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        if let photo = self.photos[indexPath.row] as? Photo {
            cell.image = photo.image
        }

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.modalPresentationCapturesStatusBarAppearance = true
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
        if self.collectionView?.cellForItemAtIndexPath(indexPath) == nil {
            self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: true)
        }
    }

    func viewerControllerDidDismiss(viewerController: ViewerController) {
    }
}
