import Foundation
import UIKit

class AppIconButton: UIButton {
  init(){
    super.init(frame: CGRect())
    
    setImage(Bundle.main.icon, for: .normal)
    
    imageView!.layer.cornerRadius = 6
    imageView!.layer.cornerCurve = .continuous
    imageView!.layer.masksToBounds = true
    
    layer.shadowColor = UIColor.black.cgColor;
    layer.shadowOffset = CGSize(width: 0, height: 0);
    layer.shadowOpacity = 0.25;
    layer.shadowRadius = 10;

    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 34).isActive = true
    heightAnchor.constraint(equalTo: widthAnchor).isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
