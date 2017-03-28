import UIKit

class PhotosCollectionLayout: UICollectionViewFlowLayout {
    static let headerSize = CGFloat(69)
    class var numberOfColumns: Int {
        var isPortrait: Bool
        switch UIDevice.current.orientation {
        case .portrait, .portraitUpsideDown, .unknown, .faceUp, .faceDown:
            isPortrait = true
        case .landscapeLeft, .landscapeRight:
            isPortrait = false
        }

        var numberOfColumns = 0
        if UIDevice.current.userInterfaceIdiom == .phone {
            numberOfColumns = isPortrait ? 3 : 6
        } else {
            numberOfColumns = isPortrait ? 5 : 8
        }

        return numberOfColumns
    }

    init(isGroupedByDay: Bool = true) {
        super.init()

        let bounds = UIScreen.main.bounds
        self.itemSize = PhotosCollectionLayout.itemSize()

        if isGroupedByDay {
            headerReferenceSize = CGSize(width: bounds.size.width, height: PhotosCollectionLayout.headerSize)
        }

        self.minimumLineSpacing = 1
        self.minimumInteritemSpacing = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func itemSize() -> CGSize {
        let bounds = UIScreen.main.bounds
        let size = (bounds.width - (CGFloat(PhotosCollectionLayout.numberOfColumns) - 1)) / CGFloat(PhotosCollectionLayout.numberOfColumns)
        return CGSize(width: size, height: size)
    }

    func updateItemSize() {
        self.itemSize = PhotosCollectionLayout.itemSize()
    }
}
