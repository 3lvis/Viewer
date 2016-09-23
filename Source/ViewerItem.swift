import UIKit

public enum ViewerItemType: String {
    case Image = "image"
    case Video = "video"
}

public protocol ViewerItem {
    var type: ViewerItemType { get }
    var id: String { get }
    var placeholder: UIImage { get set }
    var assetID: String? { get }
    var url: String? { get }

    func media(_ completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ())
}
