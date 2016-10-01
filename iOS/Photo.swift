import UIKit
import Photos

struct Photo: ViewerItem {
    enum Size {
        case small
        case large
    }

    var type: ViewerItemType = .Image
    var id: String
    var placeholder = UIImage(named: "clear.png")!
    var url: String?
    var assetID: String?
    static let NumberOfSections = 20

    init(id: String) {
        self.id = id
    }

    func media(_ completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        if let assetID = self.assetID {
            if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject {
                Photo.image(for: asset, size: .large) { image in
                    completion(image, nil)
                }
            }
        } else {
            completion(self.placeholder, nil)
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
                    photo.url = "http://techslides.com/demos/sample-videos/small.mp4"
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

        guard authorizationStatus == .authorized else { fatalError("Camera Roll not authorized") }

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        if fetchResult.count > 0 {
            fetchResult.enumerateObjects ({ asset, index, stop in
                var photo = Photo(id: UUID().uuidString)
                photo.assetID = asset.localIdentifier

                if asset.duration > 0 {
                    photo.type = .Video
                }

                elements.append(photo)
            })
        }

        return elements
    }

    static func image(for asset: PHAsset, size: Photo.Size, completion: @escaping (_ image: UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast

        if size == .small {
            let targetSize = CGSize(width: 150, height: 150)
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, info in
                // WARNING: This could fail if your phone doesn't have enough storage. Since the photo is probably
                // stored in iCloud downloading it to your phone will take most of the space left making this feature fail.
                // guard let image = image else { fatalError("Couldn't get photo data for asset \(asset)") }
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        } else {
            let bounds = UIScreen.main.bounds.size
            let targetSize = CGSize(width: bounds.width * 2, height: bounds.height * 2)
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, info in
                // WARNING: This could fail if your phone doesn't have enough storage. Since the photo is probably
                // stored in iCloud downloading it to your phone will take most of the space left making this feature fail.
                // guard let image = image else { fatalError("Couldn't get photo data for asset \(asset)") }
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }

    static func checkAuthorizationStatus(completion: @escaping (_ success: Bool) -> Void) {
        let currentStatus = PHPhotoLibrary.authorizationStatus()

        guard currentStatus != .authorized else {
            completion(true)
            return
        }

        PHPhotoLibrary.requestAuthorization { authorizationStatus in
            DispatchQueue.main.async {
                if authorizationStatus == .denied {
                    completion(false)
                } else if authorizationStatus == .authorized {
                    completion(true)
                }
            }
        }
    }
}
