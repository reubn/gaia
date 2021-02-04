import Foundation
import UIKit

class PanelActionButton: UIButton {
  private let colour: UIColor
  private let deemphasise: Bool
  
  init(_ systemName: String, colour: UIColor = .systemBlue, deemphasise: Bool = false){
    self.colour = colour
    self.deemphasise = deemphasise
    
    super.init(frame: CGRect())
  
    setImage(UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    tintColor = deemphasise ? colour : .white
    backgroundColor = deemphasise ? .white : colour
    
    contentVerticalAlignment = .fill
    contentHorizontalAlignment = .fill
    imageView!.contentMode = .scaleAspectFit
    imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    layer.cornerRadius = 15
    layer.cornerCurve = .circular
    
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: 30).isActive = true
    widthAnchor.constraint(equalTo: heightAnchor, multiplier: 2).isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var isEnabled: Bool {
    didSet {
      if(deemphasise) {
        tintColor = isEnabled
          ? deemphasise ? colour : .white
          : .systemGray
        
      } else {
        backgroundColor = isEnabled
          ? deemphasise ? .white : colour
          : .systemGray
      }
      
    }
  }
}
