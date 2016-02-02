import UIKit

public protocol ViewerItem {
    var remoteID: String? { get }
    var placeholder: UIImage { get }
    var url: String? { get }

    func media(completion: (image: UIImage?) -> ())
}
