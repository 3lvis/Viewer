import UIKit

class PhotosCollectionLayout: UICollectionViewFlowLayout {
    static let headerSize = CGFloat(69)
    class var numberOfColumns: Int {
        #if os(iOS)
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
        #else
            return 6
        #endif
    }

    init(isGroupedByDay: Bool = true) {
        super.init()

        let bounds = UIScreen.main.bounds
        self.itemSize = PhotosCollectionLayout.itemSize()
        self.headerReferenceSize = CGSize(width: bounds.size.width, height: PhotosCollectionLayout.headerSize)

        #if os(iOS)
            self.minimumLineSpacing = 1
            self.minimumInteritemSpacing = 1
        #else
            let margin = CGFloat(25)
            self.minimumLineSpacing = 50
            self.minimumInteritemSpacing = margin
            self.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        #endif
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func itemSize() -> CGSize {
        #if os(iOS)
            let bounds = UIScreen.main.bounds
            let size = (bounds.width - (CGFloat(PhotosCollectionLayout.numberOfColumns) - 1)) / CGFloat(PhotosCollectionLayout.numberOfColumns)
            return CGSize(width: size, height: size)
        #else
            return CGSize(width: 260, height: 260)
        #endif
    }

    func updateItemSize() {
        self.itemSize = PhotosCollectionLayout.itemSize()
    }
}
