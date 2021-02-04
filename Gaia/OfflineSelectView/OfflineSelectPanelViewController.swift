import Foundation
import UIKit

import Mapbox
import FloatingPanel

class OfflineSelectPanelViewController: MapViewPanelViewController {
  let mapViewController: MapViewController
  lazy var offlineSelectCoordinatorView = OfflineSelectCoordinatorView(mapViewController: mapViewController, panelViewController: self)
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    super.init(title: "Downloads")
    
    self.panelButtons = [.dismiss]
    
    view.addSubview(offlineSelectCoordinatorView)
    
    offlineSelectCoordinatorView.translatesAutoresizingMaskIntoConstraints = false
    offlineSelectCoordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    offlineSelectCoordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    offlineSelectCoordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    offlineSelectCoordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  override func panelButtonTapped(button: PanelButton) {
    super.panelButtonTapped(button: button)
    
    offlineSelectCoordinatorView.panelButtonTapped(button: button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


