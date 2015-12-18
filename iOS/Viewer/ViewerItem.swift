import UIKit

public protocol ViewerItem {
    var remoteID: String? { get }
    var image: UIImage? { get set }
}
