import UIKit

class CollectionController: UICollectionViewController {
    var photos = Photo.constructElements()
    var viewerController: ViewerController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)

        NSNotificationCenter.defaultCenter().addObserverForName(HeaderView.ClearNotificationName, object: nil, queue: nil) { notification in
            self.viewerController?.dismiss(nil)
        }

        NSNotificationCenter.defaultCenter().addObserverForName(HeaderView.MenuNotificationName, object: nil, queue: nil) { notification in
            let button = notification.object as! UIButton
            let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
            let optionsController = OptionsController(sourceView: button, sourceRect: rect)
            optionsController.controllerDelegate = self
            self.viewerController?.presentViewController(optionsController, animated: true, completion: nil)
        }

        NSNotificationCenter.defaultCenter().addObserverForName(FooterView.FavoriteNotificationName, object: nil, queue: nil) { notification in
            let alertController = self.alertControllerWithTitle("Favorite pressed")
            self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
        }

        NSNotificationCenter.defaultCenter().addObserverForName(FooterView.DeleteNotificationName, object: nil, queue: nil) { notification in
            let alertController = self.alertControllerWithTitle("Delete pressed")
            self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
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

extension CollectionController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        let photo = self.photos[indexPath.row]
        cell.image = photo.placeholder

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let collectionView = self.collectionView else { return }

        self.viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView, headerViewClass: HeaderView.self, footerViewClass: FooterView.self)
        self.viewerController!.controllerDataSource = self
        self.presentViewController(self.viewerController!, animated: false, completion: nil)
    }
}

extension CollectionController: ViewerControllerDataSource {
    func viewerController(viewerController: ViewerController, itemAtIndexPath indexPath: NSIndexPath) -> ViewerItem {
        return self.photos[indexPath.row]
    }
}

extension CollectionController: OptionsControllerDelegate {
    func optionsController(optionsController: OptionsController, didSelectOption option: String) {
        self.viewerController?.dismissViewControllerAnimated(true, completion: nil)
    }
}