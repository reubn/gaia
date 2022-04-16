import Foundation
import UIKit

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: PanelViewController {
  var coordinatorView: LocationInfoCoordinatorView?
  
  init(location: LocationInfoType){
    super.init(title: "")
    
    self.panelButtons = [.dismiss]
    
    self.coordinatorView = LocationInfoCoordinatorView(panelViewController: self, location: location)
    
    guard let coordinatorView = coordinatorView else {
      return
    }
    
    view.addSubview(coordinatorView)
    
    coordinatorView.translatesAutoresizingMaskIntoConstraints = false
    coordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    coordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    coordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    coordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  override func panelButtonTapped(button: PanelButtonType) {
    super.panelButtonTapped(button: button)
    
    if let coordinatorView = coordinatorView {
      coordinatorView.panelButtonTapped(button: button)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


