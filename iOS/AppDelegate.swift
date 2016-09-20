import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let IsLightStatusBar = false

    var window: UIWindow?

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        let numberOfColumns = CGFloat(4)
        let layout = UICollectionViewFlowLayout()
        let bounds = UIScreen.main.bounds
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        let size = (bounds.width - numberOfColumns) / numberOfColumns
        layout.itemSize = CGSize(width: size, height: size)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        let remoteController = RemoteCollectionController(collectionViewLayout: layout)
        remoteController.title = "Remote"
        let remoteNavigationController = UINavigationController(rootViewController: remoteController)

        let localController = LocalCollectionController(collectionViewLayout: layout)
        localController.title = "Local"
        let localNavigationController = UINavigationController(rootViewController: localController)

        if AppDelegate.IsLightStatusBar {
            UINavigationBar.appearance().barTintColor = UIColor.orange
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            remoteNavigationController.navigationBar.barStyle = .black
            localNavigationController.navigationBar.barStyle = .black
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([remoteNavigationController, localNavigationController], animated: false)

        self.window?.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()

        return true
    }
}
