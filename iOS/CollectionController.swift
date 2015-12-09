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
        guard let collectionView = self.collectionView, existingCell = collectionView.cellForItemAtIndexPath(indexPath), photo = self.photos[indexPath.row] as? Photo else { return }

        let viewerController = ViewerController(pageIndex: indexPath.row, indexPath: indexPath, existingCell: existingCell, photo: photo, collectionView: collectionView)
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
        /*
        self.dismissViewControllerAnimated(false, completion: nil)

        let screenBound = UIScreen.mainScreen().bounds
        let transformedCell = self.cell!
        let scaleFactor = transformedCell.image!.size.width / screenBound.size.width
        transformedCell.frame = CGRectMake(0, (screenBound.size.height/2) - ((transformedCell.image!.size.height / scaleFactor)/2), screenBound.size.width, transformedCell.image!.size.height / scaleFactor)

        self.overlayView.alpha = 1.0
        guard let window = UIApplication.sharedApplication().delegate?.window?! else { return }
        window.addSubview(overlayView)
        window.addSubview(transformedCell)

        UIView.animateWithDuration(0.25, animations: {
            self.overlayView.alpha = 0.0
            transformedCell.frame = self.originalRect
            }, completion: { finished in
                if let existingCell = self.collectionView?.cellForItemAtIndexPath(self.selectedIndexPath) {
                    existingCell.alpha = 1
                }

                transformedCell.removeFromSuperview()
                self.overlayView.removeFromSuperview()
        })*/
    }
}
