import UIKit
import Photos

struct Photo: ViewerItem {
    enum Size {
        case Small, Large
    }

    var type: ViewerItemType = .Image
    var id: String
    var placeholder = UIImage(named: "clear.png")!
    var url: String?
    var isLocal: Bool = false
    static let NumberOfSections = 20

    init(id: String) {
        self.id = id
    }

    func media(completion: (image: UIImage?, error: NSError?) -> ()) {
        if self.isLocal {
            if let asset = PHAsset.fetchAssetsWithLocalIdentifiers([self.id], options: nil).firstObject {
                Photo.resolveAsset(asset as! PHAsset, size: .Large, completion: { image in
                    completion(image: image, error: nil)
                })
            }
        } else {
            completion(image: self.placeholder, error: nil)
        }
    }

    static func constructRemoteElements() -> [[ViewerItem]] {
        var sections = [[ViewerItem]]()

        for section in 0..<Photo.NumberOfSections {
            var elements = [ViewerItem]()
            for row in 0..<10 {
                var photo = Photo(id: "\(section)-\(row)")

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
                    photo.type = .Video
                default: break
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
                    var photo = Photo(id: asset.localIdentifier)

                    if asset.duration > 0 {
                        photo.type = .Video
                    }

                    photo.isLocal = true
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
