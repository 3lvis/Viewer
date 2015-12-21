import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let numberOfColumns = CGFloat(4)
        let layout = UICollectionViewFlowLayout()
        let bounds = UIScreen.mainScreen().bounds
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        let size = (bounds.width - numberOfColumns) / numberOfColumns
        layout.itemSize = CGSize(width: size, height: size)
        let controller = CollectionController(collectionViewLayout: layout)
        let navigationController = UINavigationController(navigationBarClass: FixedHeightNavigationBar.self, toolbarClass: UIToolbar.self)
        navigationController.viewControllers = [controller]

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([navigationController], animated: false)

        self.window?.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()

        return true
    }
}
