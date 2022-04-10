import Foundation
import UIKit

class PanelButton: UIButton {
  fileprivate let inset: Double?
  fileprivate let colour: UIColor
  fileprivate let backgroundColour: UIColor?
  fileprivate let deemphasise: Bool
  
  func getDefaultWeight() -> UIImage.SymbolWeight {.semibold}
  func getSize() -> CGSize {.init(width: 60, height: 30)}
  
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
    
    let size = getSize()
    layer.cornerRadius = 15
    layer.cornerCurve = .circular
    
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: size.height).isActive = true
    widthAnchor.constraint(equalToConstant: size.width).isActive = true
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
        let size = getSize()
        pulseAnimation = PulseAnimation(radius: 100, postion: .init(x: size.width / 2, y: size.height / 2))
        pulseAnimation!.backgroundColor = (self.backgroundColour ?? self.colour).cgColor
        self.layer.insertSublayer(pulseAnimation!, at: 0)
      } else {
        pulseAnimation!.stopped = true
        pulseAnimation = nil
      }
    }
  }
}

class PanelSmallButton: PanelButton {
  override func getDefaultWeight() -> UIImage.SymbolWeight {.semibold}
  override func getSize() -> CGSize {.init(width: 30, height: 30)}
}


class PulseAnimation: CALayer, CAAnimationDelegate {
  var animationGroup = CAAnimationGroup()
  var animationDuration: TimeInterval = 3
  var radius: CGFloat = 200
  
  var stopped = false
  
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
      self.pulse()
    }
  }
  
  func pulse(){
    if(self.stopped) {
      self.removeAllAnimations()
      return
    }
    
    DispatchQueue.main.async {
      self.add(self.animationGroup, forKey: "pulse")
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
    opacityAnimiation.values =   [0.4, 0.8, 0.7, 0.4, 0.0]
    opacityAnimiation.keyTimes = [0.0, 0.25, 0.5, 0.75, 1.0]
    return opacityAnimiation
  }
  
  func setupAnimationGroup() {
    self.animationGroup.duration = animationDuration + 3
    self.animationGroup.repeatCount = 1
    let defaultCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
    self.animationGroup.timingFunction = defaultCurve
    self.animationGroup.animations = [scaleAnimation(), createOpacityAnimation()]
    self.animationGroup.delegate = self
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    pulse()
  }
}
