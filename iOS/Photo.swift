import UIKit
import Photos

struct Photo: ViewerItem {
    enum Size {
        case Small, Large
    }

    var type: ViewerItemType = .Image
    var remoteID: String?
    var placeholder = UIImage(named: "clear.png")!
    var url: String?
    var local: Bool = false

    init(remoteID: String) {
        self.remoteID = remoteID
    }

    func media(completion: (image: UIImage?) -> ()) {
        if self.local {
            if let asset = PHAsset.fetchAssetsWithLocalIdentifiers([self.remoteID!], options: nil).firstObject {
                Photo.resolveAsset(asset as! PHAsset, size: .Large, completion: { image in
                    completion(image: image)
                })
            }
        } else {
            completion(image: self.placeholder)
        }
    }

    static func constructRemoteElements() -> [ViewerItem] {
        var elements = [ViewerItem]()

        for i in 1..<60 {
            var photo = Photo(remoteID: "\(i)")

            let index = Int(arc4random_uniform(6))
            switch index {
            case 0:
                photo.placeholder = UIImage(named: "0.jpg")!
                break
            case 1:
                photo.placeholder = UIImage(named: "1.jpg")!
                break
            case 2:
                photo.placeholder = UIImage(named: "2.jpg")!
                break
            case 3:
                photo.placeholder = UIImage(named: "3.jpg")!
                break
            case 4:
                photo.placeholder = UIImage(named: "4.jpg")!
                break
            case 5:
                photo.placeholder = UIImage(named: "5.png")!
                photo.url = "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_20mb.mp4"
            default: break
            }
            elements.append(photo)
        }

        return elements
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
                    var photo = Photo(remoteID: asset.localIdentifier)

                    if asset.duration > 0 {
                        photo.type = .Video
                    }

                    photo.local = true
                    elements.append(photo)
                }
            }
        }

        return elements
    }

    static func resolveAsset(asset: PHAsset, size: Photo.Size, completion: (image: UIImage?) -> Void) {
        let imageManager = PHImageManager.defaultManager()
        let requestOptions = PHImageRequestOptions()

        var targetSize = CGSizeZero
        if size == .Small {
            targetSize = CGSize(width: 300, height: 300)

            imageManager.requestImageForAsset(asset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFill, options: requestOptions) { image, info in
                if let info = info where info["PHImageFileUTIKey"] == nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(image: image)
                    })
                }
            }
        } else {
            let size = UIScreen.mainScreen().bounds.size
            targetSize = CGSize(width: size.width * 3, height: size.height * 3)
            requestOptions.deliveryMode = .HighQualityFormat

            imageManager.requestImageDataForAsset(asset, options: nil) { data, _, _, _ in
                if let data = data, image = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(image: image)
                    })
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
