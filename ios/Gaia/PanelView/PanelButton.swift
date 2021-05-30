import Foundation
import UIKit

class PanelButton: UIButton {
  fileprivate let inset: CGFloat?
  fileprivate let colour: UIColor
  fileprivate let backgroundColour: UIColor?
  fileprivate let deemphasise: Bool
  
  func getDefaultWeight() -> UIImage.SymbolWeight{.semibold}
  
  init(_ systemName: String, weight: UIImage.SymbolWeight? = nil, inset: CGFloat? = nil, colour: UIColor = .systemBlue, backgroundColour: UIColor? = nil, deemphasise: Bool = false){
    self.colour = colour
    self.backgroundColour = backgroundColour
    self.deemphasise = deemphasise
    self.inset = inset
    
    super.init(frame: CGRect())
  
    setImage(UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(weight: weight ?? getDefaultWeight())), for: .normal)
    
    tintColor = (deemphasise || (backgroundColour != nil)) ? colour : .white
    backgroundColor = backgroundColour ?? (deemphasise ? .white : colour)
    
    contentVerticalAlignment = .fill
    contentHorizontalAlignment = .fill
    imageView!.contentMode = .scaleAspectFit
    
    setSize()
  }
  
  func setSize(){
    let inset = self.inset ?? 7
    imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    
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

class PanelSmallButton: PanelButton {
  override func getDefaultWeight() -> UIImage.SymbolWeight{.semibold}

  override func setSize(){
    let inset = self.inset ?? 7
    imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    
    layer.cornerRadius = 15
    layer.cornerCurve = .circular
    
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 30).isActive = true
    heightAnchor.constraint(equalTo: widthAnchor).isActive = true
  }
}
