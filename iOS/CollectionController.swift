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
        if let existingCell = collectionView.cellForItemAtIndexPath(indexPath) {
            existingCell.alpha = 0

            guard let window = UIApplication.sharedApplication().delegate?.window?! else { return }
            let convertedRect = window.convertRect(existingCell.frame, fromView: self.collectionView!)
            let transformedCell = UIImageView(frame: convertedRect)

            if let photo = self.photos[indexPath.row] as? Photo {
                transformedCell.image = photo.image
                transformedCell.contentMode = .ScaleAspectFill
                transformedCell.clipsToBounds = true
                window.addSubview(transformedCell)

                UIView.animateWithDuration(1.0, animations: {
                    transformedCell.clipsToBounds = false
                    transformedCell.contentMode = .ScaleAspectFit
                    transformedCell.frame = UIScreen.mainScreen().bounds
                })
            }
        }

        /*
        let viewerController = ViewerController(pageIndex: indexPath.row)
        viewerController.controllerDelegate = self
        viewerController.controllerDataSource = self
        self.presentViewController(viewerController, animated: true, completion: nil)
        */
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

    func viewerControllerDidDismiss(viewerController: ViewerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
