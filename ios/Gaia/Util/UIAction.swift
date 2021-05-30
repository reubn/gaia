import Foundation
import UIKit

extension UIAction {
  convenience init(title: String, image: UIImage?, state: Bool, handler: @escaping UIActionHandler) {
    self.init(title: title, image: image, state: state ? .on : .off, handler: handler)
  }
  
  convenience init(title: String, image: UIImage?, setting: SettingsManager.Setting<Bool>, update: (() -> ())?) {
    self.init(title: title, image: image, state: setting.value, handler: {_ in setting.toggle(); update?()})
  }
}
