import UIKit

public protocol ViewerItem {
    var remoteID: String? { get }
    var placeholder: UIImage { get set }
    var url: String? { get }
    var local: Bool { get }

    func media(completion: (image: UIImage?) -> ())
}
