import Foundation
import UIKit

import Mapbox

class LayerSelectCoordinatorView: CoordinatorView {
  let mapViewController: MapViewController
  unowned let panelViewController: LayerSelectPanelViewController
  
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
  
  func done(data: Data){
    do {
      let decoder = JSONDecoder()

      let contents = try decoder.decode([LayerDefinition].self, from: data)
      
      print(contents)
      
      DispatchQueue.main.async {
        for layerDefinition in contents {
          _ = self.layerManager.newLayer(layerDefinition)
        }
        
        self.layerManager.saveLayers()
        super.done()
      }
    } catch {
      print("Unexpected error: \(error).")
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}







