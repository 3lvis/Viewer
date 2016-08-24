import UIKit
import Photos

struct Photo: ViewerItem {
    enum Size {
        case Small, Large
    }

    var type: ViewerItemType = .Image
    var assetID: String?
    var videoURL: String?
    var imageURL: String?
    static let NumberOfSections = 20

    func media(completion: (image: UIImage?, error: NSError?) -> ()) {
        if let assetID = self.assetID {
            if let asset = PHAsset.fetchAssetsWithLocalIdentifiers([assetID], options: nil).firstObject {
                Photo.resolveAsset(asset as! PHAsset, size: .Large, completion: { image in
                    completion(image: image, error: nil)
                })
            }
        } else if let url = self.imageURL {
            let session = NSURLSession(configuration: .defaultSessionConfiguration())
            let request = NSURLRequest(URL: NSURL(string: url)!)
            let task = session.dataTaskWithRequest(request) { data, _, _ in
                var image: UIImage?
                if let data = data {
                    image = UIImage(data: data)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    completion(image: image, error: nil)
                }
            }
            task.resume()
        } else {
            completion(image: nil, error: nil)
        }
    }

    static func constructRemoteElements() -> [[ViewerItem]] {
        var sections = [[ViewerItem]]()

        for section in 1..<Photo.NumberOfSections {
            var elements = [ViewerItem]()
            for row in 1..<10 {
                var photo = Photo()

                if row == 1 {
                    photo.videoURL = "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_20mb.mp4"
                    photo.type = .Video
                } else {
                    photo.imageURL = "http://placehold.it/300x300&text=image\(section * 10 + row)"
                }

                elements.append(photo)
            }
            sections.append(elements)
        }

        return sections
    }

    static func constructLocalElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        let fetchOptions = PHFetchOptions()
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        var fetchResult: PHFetchResult?

        guard authorizationStatus == .Authorized else { abort() }

        if fetchResult == nil {
            fetchResult = PHAsset.fetchAssetsWithOptions(fetchOptions)
        }

        if fetchResult?.count > 0 {
            fetchResult?.enumerateObjectsUsingBlock { object, index, stop in
                if let asset = object as? PHAsset {
                    var photo = Photo()
                    photo.assetID = asset.localIdentifier

                    if asset.duration > 0 {
                        photo.type = .Video
                    }

                    elements.append(photo)
                }
            }
        }

        return elements
    }

    static func resolveAsset(asset: PHAsset, size: Photo.Size, completion: (image: UIImage?) -> Void) {
        let imageManager = PHImageManager.defaultManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.networkAccessAllowed = true
        if size == .Small {
            let targetSize = CGSize(width: 300, height: 300)
            imageManager.requestImageForAsset(asset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFill, options: requestOptions) { image, info in
                if let info = info where info["PHImageFileUTIKey"] == nil {
                    completion(image: image)
                }
            }
        } else {
            requestOptions.version = .Original
            imageManager.requestImageDataForAsset(asset, options: requestOptions) { data, _, _, _ in
                if let data = data, image = UIImage(data: data) {
                    completion(image: image)
                } else {
                    fatalError("Couldn't get photo")
                }
            }
        }
    }

    static func checkAuthorizationStatus(completion: (success: Bool) -> Void) {
        let currentStatus = PHPhotoLibrary.authorizationStatus()

        guard currentStatus != .Authorized else {
            completion(success: true)
            return
        }

        PHPhotoLibrary.requestAuthorization { authorizationStatus in
            dispatch_async(dispatch_get_main_queue(), {
                if authorizationStatus == .Denied {
                    completion(success: false)
                } else if authorizationStatus == .Authorized {
                    completion(success: true)
                }
            })
        }
    }
}
