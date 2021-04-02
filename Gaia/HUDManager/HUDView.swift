import Foundation
import UIKit

class HUDView: UIView {
  let size = CGSize(width: 196, height: 50)
  let padding: CGFloat = 30
  
  let message: HUDMessage
  let index: Int
  let _window: UIWindow
  
  let defaultIconColour: UIColor = .secondaryLabel
  
//  lazy var visible: CGFloat = self._window.safeAreaInsets.top - 4 + (self.size.height * (CGFloat(index) + 1)) + (4 * CGFloat(index))
  lazy var visible: CGFloat = self._window.safeAreaInsets.top - 4 + self.size.height
  
  lazy var icon: UIImageView = {
    let iconSize = (size.height / 2) - 2
    
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: iconSize, height: iconSize)))
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = message.tintColour == nil ? .tertiaryLabel : defaultIconColour
    
    addSubview(imageView)
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: padding / 2).isActive = true
    imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
    imageView.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    
    return imageView
  }()
  
  lazy var title: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14.5, weight: .medium)
    label.textColor = UIColor.label
    label.textAlignment = .center
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }()
  
  init(window: UIWindow, message: HUDMessage, index: Int) {
    self.message = message
    self.index = index
    self._window = window
    
    super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
    
    layer.shadowColor = UIColor.black.cgColor;
    layer.shadowOffset = CGSize(width: 0, height: 0);
    layer.shadowOpacity = 0.25;
    layer.shadowRadius = 10;

    let subView = UIView(frame: bounds)
    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
    blur.frame = subView.bounds
    blur.autoresizingMask = subView.autoresizingMask
    blur.isUserInteractionEnabled = false

    subView.insertSubview(blur, at: 0)
    insertSubview(subView, at: 0)

    subView.layer.cornerRadius = size.height / 2
    subView.layer.cornerCurve = .circular
    subView.clipsToBounds = true
    
    _window.addSubview(self)
    
    title.text = message.title
    
    title.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    title.rightAnchor.constraint(greaterThanOrEqualTo: rightAnchor, constant: -padding).isActive = true
    
    if(message.systemName != nil) {
      icon.image = UIImage(systemName: message.systemName!, withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
      
      title.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10).isActive = true
    } else {
      title.leftAnchor.constraint(equalTo: leftAnchor, constant: padding).isActive = true
    }
    
    translatesAutoresizingMaskIntoConstraints = false
    centerXAnchor.constraint(equalTo: _window.safeAreaLayoutGuide.centerXAnchor).isActive = true
    bottomAnchor.constraint(equalTo: _window.topAnchor, constant: 0).isActive = true
    
    rightAnchor.constraint(greaterThanOrEqualTo: title.rightAnchor, constant: padding).isActive = true

//    widthAnchor.constraint(greaterThanOrEqualToConstant: size.width).isActive = true
    heightAnchor.constraint(equalToConstant: size.height).isActive = true
  }
  
  func show(){
    _window.bringSubviewToFront(self)
    layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
    
    let showDuration = 0.45

    UIView.animate(withDuration: showDuration, withCubicBezier: [0.83, 0.2, 0, 1.15]){
      self.transform = CGAffineTransform(translationX: 0, y: self.visible)
    }

    UIView.animate(withDuration: showDuration, delay: showDuration - 0.15, options: .curveEaseOut){
      self.icon.tintColor = self.message.tintColour ?? self.defaultIconColour
      self.icon.layoutIfNeeded()
    }
  }
  
  func hide(){
    UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
      self.transform = CGAffineTransform(translationX: 0, y: 0)
      self.layer.opacity = 0
    }) {_ in
      self.removeFromSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
