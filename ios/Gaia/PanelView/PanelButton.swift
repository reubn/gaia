import Foundation
import UIKit

class PanelButton: UIButton {
  private(set) var displayConfig: DisplayConfig
  
  func getDefaultWeight() -> UIImage.SymbolWeight {.semibold}
  func getSize() -> CGSize {.init(width: 60, height: 30)}
  
  init(_ displayConfig: DisplayConfig){
    self.displayConfig = displayConfig
    super.init(frame: CGRect())
    
    contentVerticalAlignment = .fill
    contentHorizontalAlignment = .fill
    imageView!.contentMode = .scaleAspectFit
    
    setDisplayConfig(displayConfig)
    setSize()
  }
  
  func setDisplayConfig(_ displayConfig: DisplayConfig){
    self.displayConfig = displayConfig
    
    setImage(UIImage(systemName: displayConfig.systemName, withConfiguration: UIImage.SymbolConfiguration(weight: displayConfig.weight ?? getDefaultWeight())), for: .normal)
    
    tintColor = (displayConfig.deemphasise || (displayConfig.backgroundColour != nil)) ? displayConfig.colour : .white
    backgroundColor = displayConfig.backgroundColour ?? (displayConfig.deemphasise ? .white : displayConfig.colour)
  }
  
  func setSize(){
    let inset = displayConfig.inset ?? 7
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
      if(displayConfig.deemphasise) {
        tintColor = isEnabled
          ? (displayConfig.deemphasise || displayConfig.backgroundColour != nil) ? displayConfig.colour : .white
          : .systemGray
        
      } else {
        backgroundColor = isEnabled
          ? displayConfig.backgroundColour ?? (displayConfig.deemphasise ? .white : displayConfig.colour)
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
        pulseAnimation!.backgroundColor = (self.displayConfig.backgroundColour ?? self.displayConfig.colour).cgColor
        self.layer.insertSublayer(pulseAnimation!, at: 0)
      } else {
        pulseAnimation!.stopped = true
        pulseAnimation = nil
      }
    }
  }
  
  struct DisplayConfig {
    var systemName: String
    var weight: UIImage.SymbolWeight? = nil
    var inset: Double? = nil
    var colour: UIColor = .systemBlue
    var backgroundColour: UIColor? = nil
    var deemphasise: Bool = false
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
