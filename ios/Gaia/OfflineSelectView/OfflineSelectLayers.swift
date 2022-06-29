import Foundation
import UIKit

import Mapbox

let filterFn: (Layer) -> Bool = {!$0.style.hasData}

class OfflineSelectLayers: UIView, CoordinatedView, LayerManagerDelegate, PanelDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
    
  lazy var layerSelectConfig = LayerSelectConfig(
    mutuallyExclusive: false,
    layerContextActions: false,
    reorderLayers: false,
    showPinned: true,
    filter: filterFn
  )

  lazy var layerSelectView = LayerSelectView(layerSelectConfig: layerSelectConfig)

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    
    super.init(frame: CGRect())

    addSubview(layerSelectView)
    
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSL")
    
    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    LayerManager.shared.filter({$0.visible && filterFn($0)})

    MapViewController.shared.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    coordinatorView.selectedLayers = nil
    
    updatePanel()
  }
  
  func update(data: Any?) {}
  
  func viewWillExit(){
    print("exit OSL")
    
    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.remove(delegate: self)
  }
  
  func compositeStyleDidChange(to _: CompositeStyle, from _: CompositeStyle?) {
    updatePanel()
  }
  
  func updatePanel(){
    let count = LayerManager.shared.visibleLayers.count
    
    let nextButton = coordinatorView.panelViewController.getPanelButton(.next)
    nextButton.isEnabled = count > 0
    
    if(count > 0) {
      let plural = count > 1 ? "Layers" : "Layer"
      coordinatorView.panelViewController.title = String(format: "%d %@ Selected", count, plural)
    } else {
      coordinatorView.panelViewController.title = "Select Layers"
    }
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .next){
      coordinatorView.selectedLayers = LayerManager.shared.compositeStyle.sortedLayers.filter(filterFn)
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
  
  func panelDidMove() {
    layerSelectView.heightDidChange()
  }
  
  func panelDidDisappear() {}
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

