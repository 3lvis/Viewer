import UIKit

class PhotosCollectionLayout: UICollectionViewFlowLayout {
    static let headerSize = CGFloat(69)
    class var numberOfColumns: Int {
        return 6
    }

    init(isGroupedByDay: Bool = true) {
        super.init()

        let bounds = UIScreen.main.bounds
        minimumLineSpacing = 1
        minimumInteritemSpacing = 1
        itemSize = PhotosCollectionLayout.itemSize()

        if isGroupedByDay {
            headerReferenceSize = CGSize(width: bounds.size.width, height: PhotosCollectionLayout.headerSize)
        }

        let margin = CGFloat(25)
        self.minimumLineSpacing = 50
        self.minimumInteritemSpacing = margin
        self.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func itemSize() -> CGSize {
        return CGSize(width: 260, height: 260)
    }

    func updateItemSize() {
        itemSize = PhotosCollectionLayout.itemSize()
    }
}
