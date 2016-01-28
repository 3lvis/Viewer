import UIKit

protocol ViewerItemControllable {
    var imageView: UIImageView { set get }
    var indexPath: NSIndexPath? { set get }
    var view: UIView! { set get }
}
