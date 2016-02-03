import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let IsLightStatusBar = false

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

        let remoteController = RemoteCollectionController(collectionViewLayout: layout)
        remoteController.title = "Remote"
        let remoteNavigationController = UINavigationController(rootViewController: remoteController)

        let localController = LocalCollectionController(collectionViewLayout: layout)
        localController.title = "Local"
        let localNavigationController = UINavigationController(rootViewController: localController)

        if AppDelegate.IsLightStatusBar {
            UINavigationBar.appearance().barTintColor = UIColor.orangeColor()
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
            remoteNavigationController.navigationBar.barStyle = .Black
            localNavigationController.navigationBar.barStyle = .Black
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([remoteNavigationController, localNavigationController], animated: false)

        self.window?.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()

        return true
    }
}
