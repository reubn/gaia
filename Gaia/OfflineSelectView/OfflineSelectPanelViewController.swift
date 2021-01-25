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
    
    self.buttons = [.dismiss]
    
    view.addSubview(offlineSelectCoordinatorView)
    
    offlineSelectCoordinatorView.translatesAutoresizingMaskIntoConstraints = false
    offlineSelectCoordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    offlineSelectCoordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    offlineSelectCoordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    offlineSelectCoordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  @objc override func dismissButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .dismiss)
  }
  
  @objc override func acceptButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .accept)
  }
  
  @objc override func rejectButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .reject)
  }
  
  @objc override func nextButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .next)
  }
  
  @objc override func previousButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .previous)
  }
  
  @objc override func newButtonTapped(_ sender: UIButton) {
    offlineSelectCoordinatorView.panelButtonTapped(button: .new)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


