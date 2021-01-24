import Foundation
import UIKit
import Mapbox
import FloatingPanel

class LayerSelectPanelViewController: MapViewPanelViewController {
  let layerSelectView: LayerSelectView
  
  init(mapViewController: MapViewController){
    self.layerSelectView = LayerSelectView(mapViewController: mapViewController)
    
    super.init(title: "Layers")
    
    self.buttons = [.new, .dismiss]
  }
  
  override func loadView() {
    super.loadView()
    setupLayerSelectView()
  }
  
  func setupLayerSelectView() {
    view.addSubview(layerSelectView)
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
//    layerSelectView.heightAnchor.constraint(equalToConstant: 100).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


