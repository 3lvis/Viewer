import UIKit

struct Item: ViewerItem {
    var type: ViewerItemType
    var remoteID: String?
    var placeholder = UIImage(named: "clear.png")!
    var url: String?

    init(remoteID: String, type: ViewerItemType) {
        self.remoteID = remoteID
        self.type = type
    }

    func media(completion: (image: UIImage?) -> ()) {
        completion(image: self.placeholder)
    }

    static func constructElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        for i in 1..<60 {

            let index = Int(arc4random_uniform(6))
            switch index {
            case 0:
                var photo = Item(remoteID: "\(i)", type: .Photo)
                photo.placeholder = UIImage(named: "0.jpg")!
                elements.append(photo)
                break
            case 1:
                var photo = Item(remoteID: "\(i)", type: .Photo)
                photo.placeholder = UIImage(named: "1.jpg")!
                elements.append(photo)
                break
            case 2:
                var photo = Item(remoteID: "\(i)", type: .Photo)
                photo.placeholder = UIImage(named: "2.jpg")!
                elements.append(photo)
                break
            case 3:
                var photo = Item(remoteID: "\(i)", type: .Photo)
                photo.placeholder = UIImage(named: "3.jpg")!
                elements.append(photo)
                break
            case 4:
                var photo = Item(remoteID: "\(i)", type: .Photo)
                photo.placeholder = UIImage(named: "4.jpg")!
                elements.append(photo)
                break
            case 5:
                var video = Item(remoteID: "\(i)", type: .Video)
                video.placeholder = UIImage(named: "5.png")!
                video.url = "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_20mb.mp4"
                elements.append(video)
            default: break
            }
        }

        return elements
    }
}
