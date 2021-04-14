import UIKit
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = MapViewController.shared
    window.makeKeyAndVisible()
    self.window = window
    
    if let url = connectionOptions.urlContexts.first?.url {
      handleURL(url: url)
    }
  }
  
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else {return}
    
    handleURL(url: url)
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
    
    // Save changes in the application's managed object context when the application transitions to the background.
    (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
  }
  
  func handleURL(url: URL) {
    let command = URLInterface.shared.decode(url: url).first ?? .invalid
    
    switch command {
      case .go(let coordinate):
        MapViewController.shared.openLocationInfoPanel(location: .map(coordinate))
      case .import(let url):
        MapViewController.shared.toggleLayerSelectPanel(keepOpen: true)
        (MapViewController.shared.lsfpc.contentViewController! as! LayerSelectPanelViewController).coordinatorView.goTo(1, data: url)
    case .download(let context):
        MapViewController.shared.toggleOfflineSelectPanel(keepOpen: true)
        OfflineManager.shared.downloadPack(context: context)
      case .invalid:
        HUDManager.shared.displayMessage(message: .urlCommandInvalid)
    }
  }
}
