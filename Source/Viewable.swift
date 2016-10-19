import UIKit

public enum ViewableType: String {
    case image
    case video
}

public protocol Viewable {
    var type: ViewableType { get }
    var id: String { get }
    var assetID: String? { get }
    var url: String? { get }
    var placeholder: UIImage { get set }

    func media(_ completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ())
}
