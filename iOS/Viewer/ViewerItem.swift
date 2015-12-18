import UIKit

public protocol ViewerItem {
    var remoteID: String? { get }
    var placeholder: UIImage? { get set }

    func media(completion: (image: UIImage?) -> ())
}
