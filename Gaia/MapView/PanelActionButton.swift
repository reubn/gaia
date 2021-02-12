import Foundation
import UIKit

class PanelActionButton: UIButton {
  private let colour: UIColor
  private let backgroundColour: UIColor?
  private let deemphasise: Bool
  
  init(_ systemName: String, weight: UIImage.SymbolWeight = .semibold, colour: UIColor = .systemBlue, backgroundColour: UIColor? = nil, deemphasise: Bool = false){
    self.colour = colour
    self.backgroundColour = backgroundColour
    self.deemphasise = deemphasise
    
    super.init(frame: CGRect())
  
    setImage(UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(weight: weight)), for: .normal)
    
    tintColor = (deemphasise || (backgroundColour != nil)) ? colour : .white
    backgroundColor = backgroundColour ?? (deemphasise ? .white : colour)
    
    contentVerticalAlignment = .fill
    contentHorizontalAlignment = .fill
    imageView!.contentMode = .scaleAspectFit
    
    setSize()
  }
  
  func setSize(){
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
          ? (deemphasise || backgroundColour != nil) ? colour : .white
          : .systemGray
        
      } else {
        backgroundColor = isEnabled
          ? backgroundColour ?? (deemphasise ? .white : colour)
          : .systemGray
      }
      
    }
  }
}

class PanelSmallActionButton: PanelActionButton {
  override func setSize(){
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 30).isActive = true
    heightAnchor.constraint(equalTo: widthAnchor).isActive = true
  }
}
