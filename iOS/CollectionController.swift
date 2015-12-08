import UIKit

class CollectionController: UICollectionViewController {
    var photos = Photo.constructElements()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    lazy var overlayView: UIView = {
        let view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

        return view
    }()

    var cell: UIImageView?
    var originalRect = CGRectZero
    var selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
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
        self.selectedIndexPath = indexPath

        if let existingCell = collectionView.cellForItemAtIndexPath(indexPath) {
            existingCell.alpha = 0

            guard let window = UIApplication.sharedApplication().delegate?.window?! else { return }

            window.addSubview(overlayView)

            let convertedRect = window.convertRect(existingCell.frame, fromView: self.collectionView!)
            self.originalRect = convertedRect
            let transformedCell = UIImageView(frame: convertedRect)
            transformedCell.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            transformedCell.contentMode = .ScaleAspectFill
            transformedCell.clipsToBounds = true

            if let photo = self.photos[indexPath.row] as? Photo {
                transformedCell.image = photo.image
                window.addSubview(transformedCell)

                let screenBound = UIScreen.mainScreen().bounds
                let scaleFactor = transformedCell.image!.size.width / screenBound.size.width
                let finalImageViewFrame = CGRectMake(0, (screenBound.size.height/2) - ((transformedCell.image!.size.height / scaleFactor)/2), screenBound.size.width, transformedCell.image!.size.height / scaleFactor)

                UIView.animateWithDuration(0.25, animations: {
                    self.overlayView.alpha = 1.0
                    transformedCell.frame = finalImageViewFrame
                    }, completion: { finished in
                        let viewerController = ViewerController(pageIndex: indexPath.row)
                        viewerController.controllerDelegate = self
                        viewerController.controllerDataSource = self
                        self.presentViewController(viewerController, animated: false, completion: {
                            transformedCell.removeFromSuperview()
                            self.cell = transformedCell
                            self.overlayView.removeFromSuperview()
                        })
                })
            }
        }
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
        })
    }
}
