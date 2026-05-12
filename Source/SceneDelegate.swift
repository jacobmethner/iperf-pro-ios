import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // 1. Ensure we have a valid windowScene
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 2. Create the SwiftUI view that provides the window contents.
        let contentView = IPerfFullAppView()

        // 3. Create the window and set the root view controller.
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: contentView)
        
        // 4. Assign to the class property 'self.window'
        self.window = window
        window.makeKeyAndVisible()
    }
    

}
