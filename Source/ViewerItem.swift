import UIKit

public protocol ViewerItem {
    var remoteID: String? { get }
    var placeholder: UIImage { get set }
    var url: String? { get set }

    func media(completion: (image: UIImage?) -> ())
}
