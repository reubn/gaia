import Foundation
import UIKit

class MapButton: UIButton {
  let buttonSize: CGFloat = 45
  
  init(){
    super.init(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
    
    let constraints = [
      NSLayoutConstraint(
        item: self,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1,
        constant: self.frame.size.height
      ),
      NSLayoutConstraint(
        item: self,
        attribute: .width,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1,
        constant: self.frame.size.width
      )
    ]
    
    self.addConstraints(constraints)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
