import Foundation
import UIKit

import FloatingPanel

class LayerSelectPanelViewController: MapViewPanelViewController {
  let mapViewController: MapViewController
  lazy var layerSelectCoordinatorView = LayerSelectCoordinatorView(mapViewController: mapViewController, panelViewController: self)
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    
    super.init(title: "Layers")
    
    self.buttons = [.dismiss]
    
    view.addSubview(layerSelectCoordinatorView)
    
    layerSelectCoordinatorView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectCoordinatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    layerSelectCoordinatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    layerSelectCoordinatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    layerSelectCoordinatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  @objc override func dismissButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .dismiss)
  }
  
  @objc override func acceptButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .accept)
  }
  
  @objc override func rejectButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .reject)
  }
  
  @objc override func nextButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .next)
  }
  
  @objc override func previousButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .previous)
  }
  
  @objc override func newButtonTapped(_ sender: UIButton) {
    layerSelectCoordinatorView.panelButtonTapped(button: .new)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


