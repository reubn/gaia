import Foundation
import UIKit

class HUDManager {
  lazy var window = UIApplication.shared.windows.first(where: {$0.isKeyWindow})
  
  var currentHUDView: HUDView?
  
  func displayMessage(message: HUDMessage){
    guard let window = window else {
      return
    }
    
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
  
  static func Quick(title: String, systemName: String? = nil, tintColour: UIColor? = nil) -> HUDMessage {
    HUDMessage(
      title: title,
      systemName: systemName,
      tintColour: tintColour,
      duration: 1.25
    )
  }
}
