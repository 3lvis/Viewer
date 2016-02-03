import UIKit

public enum ViewerItemType {
    case Image, Video
}

public protocol ViewerItem {
    var type: ViewerItemType { get }
    var remoteID: String? { get }
    var placeholder: UIImage { get set }
    var url: String? { get }
    var local: Bool { get }

    func media(completion: (image: UIImage?) -> ())
}
