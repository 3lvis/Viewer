import UIKit

struct Photo: ViewerItem {
    var remoteID: String?
    var placeholder: UIImage?

    init(remoteID: String) {
        self.remoteID = remoteID
    }

    func media(completion: (image: UIImage?) -> ()) {
        completion(image: self.placeholder)
    }

    static func constructElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        for i in 1..<60 {
            var photo = Photo(remoteID: "\(i)")

            let index = Int(arc4random_uniform(5))
            switch index {
            case 0:
                photo.placeholder = UIImage(named: "0.jpg")
                break
            case 1:
                photo.placeholder = UIImage(named: "1.jpg")
                break
            case 2:
                photo.placeholder = UIImage(named: "2.jpg")
                break
            case 3:
                photo.placeholder = UIImage(named: "3.jpg")
                break
            case 4:
                photo.placeholder = UIImage(named: "4.jpg")
                break
            default: break
            }
            elements.append(photo)
        }

        return elements
    }
}
