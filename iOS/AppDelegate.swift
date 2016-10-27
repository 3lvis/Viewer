import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let IsLightStatusBar = false

    var window: UIWindow?

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        let localController = PhotosController(useLocalPhotos: true)
        localController.title = "Local"
        let localNavigationController = UINavigationController(rootViewController: localController)

        let remoteController = PhotosController(useLocalPhotos: false)
        remoteController.title = "Remote"
        let remoteNavigationController = UINavigationController(rootViewController: remoteController)

        if AppDelegate.IsLightStatusBar {
            UINavigationBar.appearance().barTintColor = .orange
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            remoteNavigationController.navigationBar.barStyle = .black
            localNavigationController.navigationBar.barStyle = .black
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([localNavigationController, remoteNavigationController], animated: false)

        self.window!.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()

        return true
    }
}
