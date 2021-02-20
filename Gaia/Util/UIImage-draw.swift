import Foundation
import UIKit

extension UIImage {
  func draw(inFrontOf: UIImage) -> UIImage {
    let compositeImage: UIImage!

    let size = CGSize(width: self.size.width, height: self.size.height)
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    
    UIGraphicsBeginImageContext(size)
          
    inFrontOf.draw(in: rect)
    self.draw(in: rect)

    compositeImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return compositeImage
  }
}
