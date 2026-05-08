import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Create the window
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        // 2. Initialize your NEW SwiftUI View
        // Note: Ensure IPerfFullView is the name of your main SwiftUI struct
        let contentView = IPerfFullAppView()
        
        // 3. Wrap the SwiftUI view in a UIHostingController
        let rootVC = UIHostingController(rootView: contentView)
        
        // 4. (Optional) Wrap in a NavigationController if you want the native top bar
        let navigationController = UINavigationController(rootViewController: rootVC)
        navigationController.isNavigationBarHidden = true // Usually hidden since SwiftUI has its own .navigationTitle
        
        // 5. Set the root and make visible
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}
