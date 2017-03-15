import UIKit

class PhotosCollectionLayout: UICollectionViewFlowLayout {
    static let headerSize = CGFloat(69)
    class var numberOfColumns: Int {
        return 6
    }

    override init() {
        super.init()

        self.itemSize = PhotosCollectionLayout.itemSize()

        let bounds = UIScreen.main.bounds
        self.headerReferenceSize = CGSize(width: bounds.size.width, height: PhotosCollectionLayout.headerSize)

        let margin = CGFloat(55)
        self.minimumLineSpacing = margin
        self.minimumInteritemSpacing = margin
        self.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func itemSize() -> CGSize {
        return CGSize(width: 260, height: 260)
    }

    func updateItemSize() {
        self.itemSize = PhotosCollectionLayout.itemSize()
    }
}
