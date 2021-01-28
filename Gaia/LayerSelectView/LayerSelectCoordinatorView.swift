import Foundation
import UIKit

import Mapbox

class LayerSelectCoordinatorView: CoordinatorView {
  let mapViewController: MapViewController
  let panelViewController: LayerSelectPanelViewController
  
  lazy var layerManager = mapViewController.layerManager
  
  init(mapViewController: MapViewController, panelViewController: LayerSelectPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init()
    
    story = [
      LayerSelectHome(coordinatorView: self, mapViewController: mapViewController),
      LayerSelectImport(coordinatorView: self, mapViewController: mapViewController)
    ]
    
    super.ready()
  }
  
  func done(newSources: [StyleJSON.Source]){
    for source in newSources {
      _ = layerManager.newLayer(source)
    }
    
    layerManager.saveLayers()
    super.done()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}







