import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let IsLightStatusBar = false

    var window: UIWindow?

    public func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        let localController = PhotosController(dataSourceType: .local)
        localController.title = "Local"
        let localNavigationController = UINavigationController(rootViewController: localController)

        let remoteController = PhotosController(dataSourceType: .remote)
        remoteController.title = "Remote"
        let remoteNavigationController = UINavigationController(rootViewController: remoteController)

        let photoController = PhotoController()
        photoController.title = "Plain VC"
        let photoNavigationController = UINavigationController(rootViewController: photoController)

        if AppDelegate.IsLightStatusBar {
            UINavigationBar.appearance().barTintColor = .orange
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            remoteNavigationController.navigationBar.barStyle = .black
            localNavigationController.navigationBar.barStyle = .black
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([localNavigationController, remoteNavigationController, photoNavigationController], animated: false)

        self.window!.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()

        return true
    }
}
