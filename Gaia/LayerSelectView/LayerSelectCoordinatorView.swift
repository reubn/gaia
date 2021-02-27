import Foundation
import UIKit

import AnyCodable
import Mapbox
import CoreGPX


class LayerSelectCoordinatorView: CoordinatorView {
  unowned let panelViewController: LayerSelectPanelViewController
  
  init(panelViewController: LayerSelectPanelViewController){
    self.panelViewController = panelViewController
    
    super.init()
    
    story = [
      LayerSelectHome(coordinatorView: self),
      LayerSelectImport(coordinatorView: self),
      LayerSelectEdit(coordinatorView: self)
    ]
    
    super.ready()
  }
  
  func done(data optionalData: Data? = nil, url: String? = nil) -> Int {
    let data = optionalData ?? Data()
    
    var layerDefinitions: [LayerDefinition] = []
 
    let decoder = JSONDecoder()

    let jsonLayerDefinitions = try? (try? decoder.decode([LayerDefinition].self, from: data)) ?? [decoder.decode(LayerDefinition.self, from: data)]
    
    if(jsonLayerDefinitions != nil) {
      layerDefinitions = jsonLayerDefinitions!
    } else {
      let validURLScheme = url != nil && ["{x}", "{y}", "{z}"].allSatisfy({url!.contains($0)})
      
      if(validURLScheme) {
        layerDefinitions = [LayerDefinition(xyzURL: url!)]
      } else {
        let gpx = GPXParser(withData: data).parsedData()
        
        if((gpx?.tracks.count ?? 0) != 0 ) {
          layerDefinitions = [LayerDefinition(gpx: gpx!)]
        }
      }
    }
    
    if(layerDefinitions.count > 0) {
      DispatchQueue.main.async {
        let single = layerDefinitions.count == 1
        
        for layerDefinition in layerDefinitions {
          _ = LayerManager.shared.newLayer(layerDefinition, visible: single)
        }
        
        LayerManager.shared.saveLayers()
        super.done()
      }
    }
    
    return layerDefinitions.count
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
