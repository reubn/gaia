import Foundation
import UIKit

class LayerSelectViewEmpty: UIView {
  let layerManager: LayerManager
  
  lazy var title: UILabel = {
    let label = UILabel()
      
    label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    return label
  }()
  
  lazy var subtitle: UILabel = {
    let label = UILabel()
      
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    label.textColor = .tertiaryLabel
    label.numberOfLines = 0

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: title.bottomAnchor).isActive = true
    label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    return label
  }()
  
  init(layerManager: LayerManager){
    self.layerManager = layerManager
    super.init(frame: CGRect())
    
    update()
  }
  
  func update(){
    if(layerManager.layers.isEmpty){
      title.text = "You need some Layers"
      subtitle.text = "Add or Import to get started"
      isHidden = false
    } else {isHidden = true}
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
