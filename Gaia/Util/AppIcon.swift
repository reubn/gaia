import Foundation
import UIKit

// https://stackoverflow.com/a/51241158

extension Bundle {
  public var icon: UIImage? {
    
    if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
       let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let files = primary["CFBundleIconFiles"] as? [String],
       let icon = files.last {

      return UIImage(named: icon)
    }
    
    return nil
  }
}
