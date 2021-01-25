import Foundation
import UIKit

class MapButton: UIButton {
  let buttonSize: CGFloat = 45
  
  init(){
    super.init(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
    
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
    widthAnchor.constraint(equalTo: heightAnchor).isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
