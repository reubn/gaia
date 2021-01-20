import Foundation
import UIKit
import Mapbox
import FloatingPanel

class OfflineSelectPanelViewController: MapViewPanelViewController {
  let layerManager: LayerManager
  let offlineSelectView: OfflineSelectView
  
  init(layerManager: LayerManager){
    self.layerManager = layerManager
    self.offlineSelectView = OfflineSelectView(layerManager: layerManager)
    
    super.init(title: "Downloads")
  }
  
  override func loadView() {
    super.loadView()
    setupOfflineSelectView()
  }
  
  func setupOfflineSelectView() {
    view.addSubview(offlineSelectView)
    offlineSelectView.translatesAutoresizingMaskIntoConstraints = false
    offlineSelectView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    offlineSelectView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    offlineSelectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    offlineSelectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    offlineSelectView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


