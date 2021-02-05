import Foundation
import UIKit

import Mapbox

class LayerSelectView: UIScrollView, LayerManagerDelegate {
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  
  let stack = UIStackView()
  
  init(mutuallyExclusive: Bool, mapViewController: MapViewController){
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())
  
    layerManager.multicastStyleDidChangeDelegate.add(delegate: self)
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true

    stack.axis = .vertical
    stack.alignment = .leading
    stack.distribution = .fill
    stack.spacing = 0
    
    addSubview(stack)
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    stack.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    stack.topAnchor.constraint(equalTo: topAnchor, constant: layer.cornerRadius / 2).isActive = true
    stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    stack.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    
    layerManager.layerGroups.forEach({
      let section = Section(group: $0, mutuallyExclusive: mutuallyExclusive, layerManager: layerManager, mapViewController: mapViewController)
      
      stack.addArrangedSubview(section)
      
      section.translatesAutoresizingMaskIntoConstraints = false
      section.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    })
  }
  
  func styleDidChange(style _: Style) {
    stack.arrangedSubviews.forEach({
      ($0 as! Section).update()
    })
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}







