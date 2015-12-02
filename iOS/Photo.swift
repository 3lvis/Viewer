import UIKit

struct Photo: ViewerItem {
    var id: Int
    var image: UIImage?

    init(id: Int) {
        self.id = id
    }

    static func constructElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        for i in 1..<60 {
            var photo = Photo(id: i)
            photo.image = UIImage(named: "photo.jpg")
            elements.append(photo)
        }

        return elements
    }
}
