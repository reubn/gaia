import Foundation
import UIKit

class PanelButton: UIButton {
  fileprivate let inset: Double?
  fileprivate let colour: UIColor
  fileprivate let backgroundColour: UIColor?
  fileprivate let deemphasise: Bool
  
  func getDefaultWeight() -> UIImage.SymbolWeight{.semibold}
  
  init(_ systemName: String, weight: UIImage.SymbolWeight? = nil, inset: Double? = nil, colour: UIColor = .systemBlue, backgroundColour: UIColor? = nil, deemphasise: Bool = false){
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
  
  fileprivate var pulseAnimation: PulseAnimation?
  var isPulsing: Bool = false {
    didSet {
      if(oldValue == isPulsing) {return}
          
      if(isPulsing){
        pulseAnimation = PulseAnimation(radius: 100, postion: .init(x: 30, y: 15))
        pulseAnimation!.animationDuration = 2
        pulseAnimation!.backgroundColor = self.colour.cgColor
        self.layer.insertSublayer(pulseAnimation!, at: 0)
      } else {
        pulseAnimation!.removeAllAnimations()
        pulseAnimation = nil
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


class PulseAnimation: CALayer {
  var animationGroup = CAAnimationGroup()
  var animationDuration: TimeInterval = 1.5
  var radius: CGFloat = 200
  
  override init(layer: Any) {
    super.init(layer: layer)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(radius: CGFloat, postion: CGPoint){
    super.init()
    self.backgroundColor = UIColor.black.cgColor
    self.contentsScale = UIScreen.main.scale
    self.opacity = 0
    self.radius = radius
    self.position = postion
    
    self.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
    self.cornerRadius = radius
    
    DispatchQueue.global(qos: .default).async {
      self.setupAnimationGroup()
      DispatchQueue.main.async {
        self.add(self.animationGroup, forKey: "pulse")
      }
    }
  }
  
  func scaleAnimation() -> CABasicAnimation {
    let scaleAnimaton = CABasicAnimation(keyPath: "transform.scale.xy")
    scaleAnimaton.fromValue = 0
    scaleAnimaton.toValue = 1
    scaleAnimaton.duration = animationDuration
    return scaleAnimaton
  }
  
  func createOpacityAnimation() -> CAKeyframeAnimation {
    let opacityAnimiation = CAKeyframeAnimation(keyPath: "opacity")
    opacityAnimiation.duration = animationDuration
    opacityAnimiation.values = [0.4, 0.8, 0]
    opacityAnimiation.keyTimes = [0, 0.3, 1]
    return opacityAnimiation
  }
  
  func setupAnimationGroup() {
    self.animationGroup.duration = animationDuration
    self.animationGroup.repeatCount = .infinity
    let defaultCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
    self.animationGroup.timingFunction = defaultCurve
    self.animationGroup.animations = [scaleAnimation(), createOpacityAnimation()]
  }
  
  
}
