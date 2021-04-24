import Foundation
import UIKit

class SectionLabel: UILabel {
  let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
  
  init(){
    super.init(frame: CGRect())
    
    font = UIFont.boldSystemFont(ofSize: 12)

    layer.cornerRadius = 5
    layer.cornerCurve = .continuous
    layer.masksToBounds = true
  }
  
  override var backgroundColor: UIColor? {
    didSet {
      textColor = backgroundColor == .systemYellow ? .black : .white
    }
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
