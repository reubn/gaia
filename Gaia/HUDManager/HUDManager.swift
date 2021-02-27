import Foundation
import UIKit

class HUDManager {
  lazy var window = UIApplication.shared.windows.first(where: {$0.isKeyWindow})!
  
  var currentHUDView: HUDView?
  
  func displayMessage(message: HUDMessage){
    let hudView = HUDView(
      window: window,
      message: message,
      index: 0
    )
    
    if(currentHUDView != nil) {
      currentHUDView!.hide()
    }
    
    currentHUDView = hudView
    hudView.show()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
      self.currentHUDView = nil
      
      hudView.hide()
    }
  }
  
  static let shared = HUDManager()
}

struct HUDMessage: Hashable {
  let title: String
  var systemName: String? = nil
  
  var tintColour: UIColor? = nil
  
  var duration: Double = 2
}
