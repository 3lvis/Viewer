import UIKit
import Photos

struct Section {
    var photos = [Photo]()
    let groupedDate: String

    init(groupedDate: String) {
        self.groupedDate = groupedDate
    }
}

struct Photo: Viewable {
    var placeholder = UIImage()

    enum Size {
        case small
        case large
    }

    var type: ViewableType = .image
    var id: String
    var url: String?
    var assetID: String?

    init(id: String) {
        self.id = id
    }

    func media(_ completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        if let assetID = self.assetID {
            if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject {
                Photo.image(for: asset) { image in
                    completion(image, nil)
                }
            }
        } else {
            completion(self.placeholder, nil)
        }
    }

    static func constructRemoteElements() -> [Section] {
        var sections = [Section]()
        let numberOfSections = 20

        for sectionIndex in 10 ..< numberOfSections {
            var photos = [Photo]()
            for row in 0 ..< 10 {
                var photo = Photo(id: "\(sectionIndex)-\(row)")

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
                    photo.type = .video
                default: break
                }
                photos.append(photo)
            }

            let groupedDate = "\(sectionIndex)-12-2016"
            var section = Section(groupedDate: groupedDate)
            section.photos = photos
            sections.append(section)
        }

        return sections
    }

    static func constructLocalElements() -> [Section] {
        var sections = [Section]()

        let fetchOptions = PHFetchOptions()
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()

        guard authorizationStatus == .authorized else { fatalError("Camera Roll not authorized") }

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        if fetchResult.count > 0 {
            fetchResult.enumerateObjects({ asset, index, stop in
                let groupedDate = asset.creationDate?.groupedDateString() ?? ""
                var foundSection = Section(groupedDate: groupedDate)
                var foundIndex: Int?
                for (index, section) in sections.enumerated() {
                    if section.groupedDate == groupedDate {
                        foundSection = section
                        foundIndex = index
                    }
                }

                var photo = Photo(id: UUID().uuidString)
                photo.assetID = asset.localIdentifier

                if asset.duration > 0 {
                    photo.type = .video
                }

                foundSection.photos.append(photo)
                if let foundIndex = foundIndex {
                    sections[foundIndex] = foundSection
                } else {
                    sections.append(foundSection)
                }
            })
        }

        return sections
    }

    static func thumbnail(for asset: PHAsset) -> UIImage? {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast

        var returnedImage: UIImage?
        let scaleFactor = UIScreen.main.scale
        let itemSize = CGSize(width: 150, height: 150)
        let targetSize = CGSize(width: itemSize.width * scaleFactor, height: itemSize.height * scaleFactor)
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, info in
            // WARNING: This could fail if your phone doesn't have enough storage. Since the photo is probably
            // stored in iCloud downloading it to your phone will take most of the space left making this feature fail.
            // guard let image = image else { fatalError("Couldn't get photo data for asset \(asset)") }

            returnedImage = image
        }

        return returnedImage
    }

    static func image(for asset: PHAsset, completion: @escaping (_ image: UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .fast

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

extension Date {

    func groupedDateString() -> String {
        let noTimeDate = Calendar.current.startOfDay(for: self)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let groupedDateString = dateFormatter.string(from: noTimeDate)

        return groupedDateString
    }
}
