import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let layout = UICollectionViewFlowLayout()
        let bounds = UIScreen.mainScreen().bounds
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        let size = (bounds.width - 4) / 4
        layout.itemSize = CGSize(width: size, height: size)
        let controller = CollectionController(collectionViewLayout: layout)
        let navigationController = UINavigationController(rootViewController: controller)
        self.window?.rootViewController = navigationController

        self.window!.makeKeyAndVisible()

        return true
    }
}
