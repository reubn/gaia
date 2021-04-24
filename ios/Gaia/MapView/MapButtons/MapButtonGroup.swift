import Foundation
import UIKit

class MapButtonGroup: UIStackView {
  init(arrangedSubviews: [UIView]) {
    super.init(frame:CGRect())

    for (index, view) in arrangedSubviews.enumerated() {
      if(index != 0) {addArrangedSubview(MapButtonGroupSeparator())}
      addArrangedSubview(view)
    }

    axis = .vertical
    alignment = .fill
    distribution = .fillProportionally
    spacing = 0

    clipsToBounds = false;
    layer.shadowColor = UIColor.black.cgColor;
    layer.shadowOffset = CGSize(width: 0, height: 0);
    layer.shadowOpacity = 0.25;
    layer.shadowRadius = 10;
    
    let subView = UIView(frame: bounds)
    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
    
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
    blur.frame = subView.bounds
    blur.autoresizingMask = subView.autoresizingMask
    blur.isUserInteractionEnabled = false

    subView.insertSubview(blur, at: 0)
    insertSubview(subView, at: 0)
    
    subView.layer.cornerRadius = 8
    subView.layer.masksToBounds = true
    subView.clipsToBounds = true
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class MapButtonGroupSeparator: UIView {
  init(){
    super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.5))
    backgroundColor = UIColor.systemFill.withAlphaComponent(0.25)
    
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: 0.5).isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
