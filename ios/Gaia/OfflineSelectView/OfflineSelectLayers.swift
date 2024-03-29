import Foundation
import UIKit

import Mapbox

class OfflineSelectLayers: UIView, CoordinatedView, LayerManagerDelegate, PanelDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
    
  lazy var layerSelectConfig = LayerSelectConfig(
    mutuallyExclusive: false,
    layerContextActions: false,
    reorderLayers: false,
    showPinned: true
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

    MapViewController.shared.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    coordinatorView.selectedLayers = nil
    
    updatePanel()
  }
  
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
      coordinatorView.selectedLayers = LayerManager.shared.compositeStyle.sortedLayers
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

