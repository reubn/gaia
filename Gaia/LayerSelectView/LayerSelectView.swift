import Foundation
import UIKit

import Mapbox

class LayerSelectView: UIScrollView, UIScrollViewDelegate, LayerManagerDelegate {
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  let multicastScrollViewDidScrollDelegate = MulticastDelegate<(UIScrollViewDelegate)>()
  
  let stack = UIStackView()
  
  lazy var emptyState = LayerSelectViewEmpty(layerManager: layerManager)
  
  init(layerSelectConfig: LayerSelectConfig, mapViewController: MapViewController){
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())
  
    layerManager.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    
    delegate = self
    
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
    
    stack.addSubview(emptyState)
    
    emptyState.translatesAutoresizingMaskIntoConstraints = false
    emptyState.topAnchor.constraint(equalTo: topAnchor).isActive = true
    emptyState.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    emptyState.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor).isActive = true
    
    emptyState.update()
    
    layerManager.layerGroups.forEach({
      let section = Section(group: $0, layerSelectConfig: layerSelectConfig, layerManager: layerManager, mapViewController: mapViewController, scrollView: self)

      stack.addArrangedSubview(section)

      section.translatesAutoresizingMaskIntoConstraints = false
      section.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    })
  }
  
  func compositeStyleDidChange(compositeStyle _: CompositeStyle) {
    stack.arrangedSubviews.forEach({
      ($0 as! Section).update()
    })
    
    emptyState.update()
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    multicastScrollViewDidScrollDelegate.invoke(invocation: {$0.scrollViewDidScroll?(scrollView)})
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
