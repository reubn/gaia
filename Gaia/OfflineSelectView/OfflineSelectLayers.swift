import Foundation
import UIKit

import Mapbox

class OfflineSelectLayers: UIView, CoordinatedView {
  let coordinatorView: OfflineSelectCoordinatorView
  let layerManager: LayerManager

  init(coordinatorView: OfflineSelectCoordinatorView, layerManager: LayerManager){
    self.coordinatorView = coordinatorView
    self.layerManager = layerManager
    
    super.init(frame: CGRect())
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSL")
    
    coordinatorView.mapViewController.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.title = "Select Layers"
    coordinatorView.panelViewController.buttons = [.okay]
  }
  
  func viewWillExit(){
    print("exit OSL")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept){
      coordinatorView.forward()
    } else if(button == .reject){
      coordinatorView.back()
    }
  }
}

