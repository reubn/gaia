import Foundation
import UIKit

let hasHomeButton: Bool = {
  guard let window = (UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows.first else {
    return false
  }
  
  return window.safeAreaInsets.bottom == 0
}()
