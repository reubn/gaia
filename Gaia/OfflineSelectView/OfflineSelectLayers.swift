import Foundation
import UIKit

import Mapbox

class OfflineSelectLayers: UIView, CoordinatedView, LayerManagerDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerSelectConfig = LayerSelectConfig(mutuallyExclusive: false, layerContextActions: false, reorderLayers: false, layerEditDelegate: nil)
  
  lazy var layerManager = mapViewController.layerManager
  lazy var layerSelectView = LayerSelectView(layerSelectConfig: layerSelectConfig, mapViewController: mapViewController)

  init(coordinatorView: OfflineSelectCoordinatorView, mapViewController: MapViewController){
    self.coordinatorView = coordinatorView
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())
    
    layerManager.multicastStyleDidChangeDelegate.add(delegate: self)
    
    addSubview(layerSelectView)
    
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  func viewWillEnter(){
    print("enter OSL")
    
    coordinatorView.mapViewController.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    coordinatorView.selectedLayers = nil
    
    updatePanel()
  }
  
  func viewWillExit(){
    print("exit OSL")
  }
  
  func styleDidChange(style: Style) {
    updatePanel()
  }
  
  func updatePanel(){
    let count = layerManager.activeLayers.count
    
    let nextButton = coordinatorView.panelViewController.getPanelButton(.next)
    nextButton.isEnabled = count > 0
    
    if(count > 0) {
      let plural = count > 1 ? "Layers" : "Layer"
      coordinatorView.panelViewController.title = String(format: "%d %@ Selected", count, plural)
    } else {
      coordinatorView.panelViewController.title = "Select Layers"
    }
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .next){
      coordinatorView.selectedLayers = layerManager.sortedLayers
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

