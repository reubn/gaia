import Foundation
import UIKit

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: PanelViewController {
  lazy var coordinatorView = LocationInfoCoordinatorView(panelViewController: self)
  
  let location: LocationInfoType
  
  init(location: LocationInfoType){
    self.location = location
    super.init(title: "")
    
    self.panelButtons = [.dismiss]
    
    view.addSubview(coordinatorView)
    
    coordinatorView.translatesAutoresizingMaskIntoConstraints = false
    coordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    coordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    coordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    coordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  override func panelButtonTapped(button: PanelButtonType) {
    super.panelButtonTapped(button: button)
    
    coordinatorView.panelButtonTapped(button: button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


