import Foundation
import UIKit

extension UIImage {
  func draw(inFrontOf: UIImage) -> UIImage {
    let compositeImage: UIImage!
    
    let maxWidth = max(self.size.width, inFrontOf.size.width)
    let maxHeight = max(self.size.height, inFrontOf.size.height)

    let maxSize = CGSize(width: maxWidth, height: maxHeight)
    
    UIGraphicsBeginImageContext(maxSize)
          
    inFrontOf.draw(at: CGPoint(x: (maxWidth / 2) - (inFrontOf.size.width / 2), y: (maxHeight / 2) - (inFrontOf.size.height / 2)))
    self.draw(at: CGPoint(x: (maxWidth / 2) - (size.width / 2), y: (maxHeight / 2) - (size.height / 2)))

    compositeImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return compositeImage
  }
}
