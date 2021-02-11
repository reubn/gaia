import Foundation
import UIKit

import Mapbox
import FloatingPanel

class OfflineSelectPanelViewController: MapViewPanelViewController {
  let mapViewController: MapViewController
  lazy var coordinatorView = OfflineSelectCoordinatorView(mapViewController: mapViewController, panelViewController: self)
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    super.init(title: "Downloads")
    
    self.panelButtons = [.dismiss]
    
    view.addSubview(coordinatorView)
    
    coordinatorView.translatesAutoresizingMaskIntoConstraints = false
    coordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    coordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    coordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    coordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  override func panelButtonTapped(button: PanelButton) {
    super.panelButtonTapped(button: button)
    
    coordinatorView.panelButtonTapped(button: button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


