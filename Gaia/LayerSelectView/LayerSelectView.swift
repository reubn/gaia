import Foundation
import UIKit

import Mapbox

class LayerSelectView: UIScrollView {
  let stack: UIStackView
  
  init(mapViewController: MapViewController){
    self.stack = UIStackView()
    
    super.init(frame: CGRect())
    
    let layerManager = mapViewController.layerManager
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true
    
//    self.backgroundColor = UIColor.red
//    self.isUserInteractionEnabled = false
    
    stack.axis = .vertical
    stack.alignment = .leading
    stack.distribution = .fill
    stack.spacing = 30
    stack.translatesAutoresizingMaskIntoConstraints = false
    
//    stack.backgroundColor = UIColor.orange
    
    addSubview(stack)
    
    stack.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    stack.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    stack.topAnchor.constraint(equalTo: topAnchor, constant: layer.cornerRadius / 2).isActive = true
    stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    stack.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    
    layerManager.layerGroups.forEach({
      if(layerManager.getLayers(layerGroup: $0) == nil) {return}
      
      let section = Section(group: $0, layerManager: layerManager, mapViewController: mapViewController)
      
      stack.addArrangedSubview(section)
      
      section.translatesAutoresizingMaskIntoConstraints = false
      section.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    })
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}







