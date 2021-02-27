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
    
    if(layerSelectConfig.showFavourites) {
      var favouritesLayerSelectConfig = layerSelectConfig
      favouritesLayerSelectConfig.reorderLayers = false
      
      let favouritesSection = Section(
        group: LayerGroup(id: "favourite", name: "Favourites", colour: .systemOrange, selectionFunction: {
          LayerManager.shared.favouriteLayers.sorted(by: LayerManager.shared.layerSortingFunction)
        }),
        layerSelectConfig: favouritesLayerSelectConfig,
        scrollView: self
      )
      
      stack.addArrangedSubview(favouritesSection)

      favouritesSection.translatesAutoresizingMaskIntoConstraints = false
      favouritesSection.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    LayerManager.shared.layerGroups.forEach({
      let section = Section(
        group: $0,
        layerSelectConfig: layerSelectConfig,
        scrollView: self
      )

      stack.addArrangedSubview(section)

      section.translatesAutoresizingMaskIntoConstraints = false
      section.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    })
    
    if(layerSelectConfig.showDisabled.contains(.section)) {
      var disabledLayerSelectConfig = layerSelectConfig
      disabledLayerSelectConfig.reorderLayers = false
      
      let disabledSection = Section(
        group: LayerGroup(id: "disabled", name: "Disabled", colour: .systemGray, selectionFunction: {
          LayerManager.shared.disabledLayers.sorted(by: LayerManager.shared.layerSortingFunction)
        }),
        layerSelectConfig: disabledLayerSelectConfig,
        scrollView: self,
        normallyCollapsed: true
      )
      
      stack.addArrangedSubview(disabledSection)

      disabledSection.translatesAutoresizingMaskIntoConstraints = false
      disabledSection.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
  }
  
  func compositeStyleDidChange(compositeStyle _: CompositeStyle) {
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
