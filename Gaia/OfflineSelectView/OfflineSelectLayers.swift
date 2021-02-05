import Foundation
import UIKit

import Mapbox

class OfflineSelectLayers: UIView, CoordinatedView, LayerManagerDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  lazy var layerSelectView = LayerSelectView(mutuallyExclusive: false, mapViewController: mapViewController)

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
    coordinatorView.panelViewController.title = "Select Layers"
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    coordinatorView.selectedLayers = nil
    
    updateNextButton()
  }
  
  func viewWillExit(){
    print("exit OSL")
  }
  
  func styleDidChange(style: Style) {
    updateNextButton()
  }
  
  func updateNextButton(){
    let nextButton = coordinatorView.panelViewController.getPanelButton(.next)
    nextButton.isEnabled = layerManager.activeLayers.count > 0
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

