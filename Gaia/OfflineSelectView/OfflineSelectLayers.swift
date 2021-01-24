import Foundation
import UIKit

import Mapbox

class OfflineSelectLayers: UIView, CoordinatedView {
  let coordinatorView: OfflineSelectCoordinatorView
  
  let mapViewController: MapViewController
  lazy var layerManager = mapViewController.layerManager
  
  lazy var layerSelectView = LayerSelectView(mapViewController: mapViewController)

  init(coordinatorView: OfflineSelectCoordinatorView, mapViewController: MapViewController){
    self.coordinatorView = coordinatorView
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())
//    backgroundColor = .systemBlue
//    layerSelectView.backgroundColor = .systemRed
    
    addSubview(layerSelectView)
    
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    
//    layerSelectView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor).isActive = true
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSL")
    
    coordinatorView.mapViewController.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.title = "Select Layers"
    coordinatorView.panelViewController.buttons = [.previous, .next]
    
    coordinatorView.selectedStyle = nil
  }
  
  func viewWillExit(){
    print("exit OSL")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .next){
      coordinatorView.selectedStyle = layerManager.style
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
}

