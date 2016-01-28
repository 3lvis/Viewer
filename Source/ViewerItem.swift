import UIKit

public enum ViewerItemType {
    case Photo, Video
}

public protocol ViewerItem {
    var type: ViewerItemType { get set }
    var remoteID: String? { get }
    var placeholder: UIImage { get set }
    var url: String? { get set }

    func media(completion: (image: UIImage?) -> ())
}
