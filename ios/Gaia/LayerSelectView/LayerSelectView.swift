import Foundation
import UIKit

import Mapbox

class LayerSelectView: UIScrollView, UIScrollViewDelegate, LayerManagerDelegate {
  let multicastScrollViewDidScrollDelegate = MulticastDelegate<(UIScrollViewDelegate)>()
  
  let stack = UIStackView()
  
  lazy var emptyState = LayerSelectViewEmpty()
  
  init(layerSelectConfig: LayerSelectConfig){
    super.init(frame: CGRect())
  
    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    
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
    
    if(layerSelectConfig.showUngrouped) {
      var ungroupedLayerSelectConfig = layerSelectConfig
      ungroupedLayerSelectConfig.reorderLayers = false
      
      let ungroupedSection = Section(
        group: LayerGroup(id: "", name: "Ungrouped", colour: .systemRed, selectionFunction: {
          LayerManager.shared.ungroupedLayers.sorted(by: LayerManager.shared.layerSortingFunction)
        }),
        layerSelectConfig: ungroupedLayerSelectConfig,
        scrollView: self,
        layerCanDrop: {_ in false}
      )
      
      stack.addArrangedSubview(ungroupedSection)

      ungroupedSection.translatesAutoresizingMaskIntoConstraints = false
      ungroupedSection.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
    
    if(layerSelectConfig.showPinned) {
      var pinnedLayerSelectConfig = layerSelectConfig
      pinnedLayerSelectConfig.reorderLayers = false
      
      let pinnedSection = Section(
        group: LayerGroup(id: "pinned", name: "Pins", colour: .systemIndigo, selectionFunction: {
          LayerManager.shared.pinnedLayers.sorted(by: LayerManager.shared.layerSortingFunction)
        }),
        layerSelectConfig: pinnedLayerSelectConfig,
        scrollView: self,
        layerCanDrop: {layer in !layer.pinned},
        layerDidDrag: {layer in layer.pinned = false},
        layerDidDrop: {layer in layer.pinned = true}
      )
      
      stack.addArrangedSubview(pinnedSection)

      pinnedSection.translatesAutoresizingMaskIntoConstraints = false
      pinnedSection.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    LayerManager.shared.groups.forEach({
      let section = Section(
        group: $0,
        layerSelectConfig: layerSelectConfig,
        scrollView: self
      )

      stack.addArrangedSubview(section)

      section.translatesAutoresizingMaskIntoConstraints = false
      section.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    })
  }
  
  func compositeStyleDidChange(to _: CompositeStyle, from _: CompositeStyle?) {
    stack.arrangedSubviews.forEach({
      ($0 as! Section).update()
    })
    
    emptyState.update()
  }
  
  func heightDidChange() {
    multicastScrollViewDidScrollDelegate.invoke(invocation: {$0.scrollViewDidScroll?(self)})
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    multicastScrollViewDidScrollDelegate.invoke(invocation: {$0.scrollViewDidScroll?(scrollView)})
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
