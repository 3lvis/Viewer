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

            let index = Int(arc4random_uniform(3))
            switch index {
            case 0:
                photo.image = UIImage(named: "a.jpg")
                break
            case 1:
                photo.image = UIImage(named: "b.jpg")
                break
            case 2:
                photo.image = UIImage(named: "c.jpg")
                break
            default: break
            }
            elements.append(photo)
        }

        return elements
    }
}
