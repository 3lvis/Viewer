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

            let index = Int(arc4random_uniform(5))
            switch index {
            case 0:
                photo.image = UIImage(named: "0.jpg")
                break
            case 1:
                photo.image = UIImage(named: "1.jpg")
                break
            case 2:
                photo.image = UIImage(named: "2.jpg")
                break
            case 3:
                photo.image = UIImage(named: "3.jpg")
                break
            case 4:
                photo.image = UIImage(named: "4.jpg")
                break
            default: break
            }
            elements.append(photo)
        }

        return elements
    }
}
