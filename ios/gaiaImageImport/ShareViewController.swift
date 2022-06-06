import UIKit
import UniformTypeIdentifiers
import CoreLocation

class CustomShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
      if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem ,
         let itemProvider = inputItem.attachments?.first {
        itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier) {(url, error) in
          if
            let imageURL = url as? URL,
            let data = try? Data(contentsOf: imageURL),
            let coordinate = CLLocationCoordinate2D(image: data){
            let command = URLInterface.Command.go(coordinate)
            
            if let gaiaURL = URLInterface.shared.encode(commands: [command]){
              self.openURL(gaiaURL)
              self.extensionContext?.completeRequest(returningItems: [])
            } else {
              self.error()
            }
            
          }
        }
      } else {
        self.error()
      }
  }
  
  func error(){
    let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
    self.extensionContext?.cancelRequest(withError: error)
  }
  
  @objc @discardableResult func openURL(_ url: URL) -> Bool {
    var responder: UIResponder? = self
    while responder != nil {
      if let application = responder as? UIApplication {
        return application.perform(#selector(openURL(_:)), with: url) != nil
      }
      responder = responder?.next
    }
    return false
  }
}

@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
    // 2: set the ViewControllers
    self.setViewControllers([CustomShareViewController()], animated: false)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
