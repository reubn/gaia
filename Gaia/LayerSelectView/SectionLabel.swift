import Foundation
import UIKit

class SectionLabel: UILabel {
  var insets: UIEdgeInsets
  
  init(insets: UIEdgeInsets){
    self.insets = insets
    super.init(frame: CGRect())
  }

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: insets))
  }
  
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    
    return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
