import UIKit

struct Photo {
    var id: Int

    init(id: Int) {
        self.id = id
    }

    static func constructElements() -> [Photo] {
        var elements = [Photo]()

        for i in 1..<400 {
            let photo = Photo(id: i)
            elements.append(photo)
        }

        return elements
    }
}

class CollectionController: UICollectionViewController {
    var photos = Photo.constructElements()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }
}

extension CollectionController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
        let photo = self.photos[indexPath.row]
        cell.text = String(photo.id)

        return cell
    }
}
