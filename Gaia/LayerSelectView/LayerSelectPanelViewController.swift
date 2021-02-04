import Foundation
import UIKit

import FloatingPanel

class LayerSelectPanelViewController: MapViewPanelViewController {
  let mapViewController: MapViewController
  lazy var layerSelectCoordinatorView = LayerSelectCoordinatorView(mapViewController: mapViewController, panelViewController: self)
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    
    super.init(title: "Layers")
    
    self.panelButtons = [.dismiss]
    
    view.addSubview(layerSelectCoordinatorView)
    
    layerSelectCoordinatorView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectCoordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    layerSelectCoordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    layerSelectCoordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    layerSelectCoordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  override func panelButtonTapped(button: PanelButton) {
    super.panelButtonTapped(button: button)
    
    layerSelectCoordinatorView.panelButtonTapped(button: button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


