import UIKit

extension NSIndexPath {
    enum Direction {
        case Forward
        case Backward
        case Same
    }

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

    class func indexPathForIndex(collectionView: UICollectionView, index: Int) -> NSIndexPath? {
        var count = 0
        let sections = collectionView.numberOfSections()
        for section in 0..<sections {
            let rows = collectionView.numberOfItemsInSection(section)
            if index >= count && index < count + rows {
                let foundRow = index - count
                return NSIndexPath(forRow: foundRow, inSection: section)
            }
            count += rows
        }

        return nil
    }

    func totalRow(collectionView: UICollectionView) -> Int {
        var count = 0
        let sections = collectionView.numberOfSections()
        for section in 0..<sections {
            if section < self.section {
                let rows = collectionView.numberOfItemsInSection(section)
                count += rows
            }
        }

        return count + self.row
    }

    func compareDirection(indexPath: NSIndexPath) -> Direction {
        let current = self.row * self.section
        let coming = indexPath.row * indexPath.section

        if current == coming {
            return .Same
        } else if current < coming {
            return .Forward
        } else {
            return .Backward
        }
    }
}
