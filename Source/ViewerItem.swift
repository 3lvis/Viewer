import UIKit

public enum ViewerItemType: String {
    case Image = "image"
    case Video = "video"
}

public protocol ViewerItem {
    // We need the type to know if your viewer is either an image or a video
    var type: ViewerItemType { get }

    // A PHAsset local identifier
    var assetID: String? { get }

    // The url to be loaded, used for video mostly, for images we'll just use the media block
    var videoURL: String? { get }

    // If you want to use a static image you need to provide an id, it can either be a string or a number
    // var id: AnyObject? { get }
    // var image: UIImage? { get }

    // You need to provide this block for loading the images
    func media(completion: (image: UIImage?, error: NSError?) -> ())
}
