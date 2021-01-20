import Foundation
import UIKit
import Mapbox
import FloatingPanel

class LayerSelectPanelViewController: MapViewPanelViewController {
  let layerManager: LayerManager
  let layerSelectView: LayerSelectView
  
  init(layerManager: LayerManager){
    self.layerManager = layerManager
    self.layerSelectView = LayerSelectView(layerManager: layerManager)
    
    super.init(title: "Layers")
  }
  
  override func loadView() {
    super.loadView()
    setupLayerSelectView()
  }
  
  func setupLayerSelectView() {
    view.addSubview(layerSelectView)
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    layerSelectView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
    
//    layerSelectView.heightAnchor.constraint(equalToConstant: 100).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


