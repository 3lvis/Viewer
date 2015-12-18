# Picasso

## Usage

From your UICollectionView:

```swift
override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    guard let collectionView = self.collectionView else { return }

    let viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView, headerViewClass: HeaderView.self, footerViewClass: FooterView.self)
    viewerController.controllerDataSource = self
    self.presentViewController(viewerController!, animated: false, completion: nil)
}

extension CollectionController: ViewerControllerDataSource {
    func viewerController(viewerController: ViewerController, itemAtIndexPath indexPath: NSIndexPath) -> ViewerItem {
        return self.photos[indexPath.row]
    }
}
```
