import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        let controller = CollectionController(collectionViewLayout: layout)
        let navigationController = UINavigationController(rootViewController: controller)
        self.window?.rootViewController = navigationController

        self.window!.makeKeyAndVisible()

        return true
    }
}

