import Foundation
import UIKit

let hasHomeButton: Bool = {
  guard let window = UIApplication.shared.windows.first else {
    return false
  }
  
  return window.safeAreaInsets.bottom == 0
}()
