import Foundation
import UIKit

class HUDManager {
  lazy var window = UIApplication.shared.windows.first(where: {$0.isKeyWindow})!
  
  var messages: Set<HUDMessage> = []
  
  func displayMessage(message: HUDMessage){
    let hudView = HUDView(
      window: window,
      message: message,
      index: messages.count
    )
    
    self.messages.insert(message)
    hudView.show()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
      self.messages.remove(message)
      hudView.hide()
    }
  }
}

struct HUDMessage: Hashable {
  let title: String
  var systemName: String? = nil
  
  var tintColour: UIColor = .secondaryLabel
  
  var duration: Double = 2
  
  enum Emphasis {
    case neutral
    case positive
    case negative
  }
}
