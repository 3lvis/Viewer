import UIKit

extension NSIndexPath {
    func indexPaths(collectionView: UICollectionView) -> [NSIndexPath] {
        var indexPaths = [NSIndexPath]()

        let sections = collectionView.numberOfSections()
        for section in 0..<sections {
            let rows = collectionView.numberOfItemsInSection(section)
            for row in 0..<rows {
                indexPaths.append(NSIndexPath(forRow: row, inSection: section))
            }
        }

        return indexPaths
    }

    func next(collectionView: UICollectionView) -> NSIndexPath? {
        var found = false
        let indexPaths = self.indexPaths(collectionView)
        for indexPath in  indexPaths {
            if found == true {
                return indexPath
            }

            if indexPath == self {
                found = true
            }
        }

        return nil
    }

    func previous(collectionView: UICollectionView) -> NSIndexPath? {
        var previousIndexPath: NSIndexPath?
        let indexPaths = self.indexPaths(collectionView)
        for indexPath in indexPaths {
            if indexPath == self {
                return previousIndexPath
            }

            previousIndexPath = indexPath
        }

        return nil
    }
}
