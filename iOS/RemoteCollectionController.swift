import UIKit

class RemoteCollectionController: UICollectionViewController {
    var sections = Photo.constructRemoteElements()
    var viewerController: ViewerController?
    var optionsController: OptionsController?
    var numberOfItems = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)

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

extension RemoteCollectionController {
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = self.sections[section]

        return photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        let photos = self.sections[indexPath.section]
        let photo = photos[indexPath.row]
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

extension RemoteCollectionController: ViewerControllerDataSource {
    func numerOfItemsInViewerController(viewerController: ViewerController) -> Int {
        return self.numberOfItems
    }

    func viewerController(viewerController: ViewerController, itemAtIndexPath indexPath: NSIndexPath) -> ViewerItem {
        let photos = self.sections[indexPath.section]
        let viewerItem = photos[indexPath.row]

        return viewerItem
    }
}

extension RemoteCollectionController: OptionsControllerDelegate {
    func optionsController(optionsController: OptionsController, didSelectOption option: String) {
        self.optionsController?.dismissViewControllerAnimated(true) {
            self.viewerController?.dismiss(nil)
        }
    }
}

extension RemoteCollectionController: HeaderViewDelegate {
    func headerView(headerView: HeaderView, didPressClearButton button: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(headerView: HeaderView, didPressMenuButton button: UIButton) {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.optionsController = OptionsController(sourceView: button, sourceRect: rect)
        self.optionsController!.controllerDelegate = self
        self.viewerController?.presentViewController(self.optionsController!, animated: true, completion: nil)
    }
}

extension RemoteCollectionController: FooterViewDelegate {
    func footerView(footerView: FooterView, didPressFavoriteButton button: UIButton) {
        let alertController = self.alertControllerWithTitle("Favorite pressed")
        self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
    }

    func footerView(footerView: FooterView, didPressDeleteButton button: UIButton) {
        let alertController = self.alertControllerWithTitle("Delete pressed")
        self.viewerController?.presentViewController(alertController, animated: true, completion: nil)
    }
}