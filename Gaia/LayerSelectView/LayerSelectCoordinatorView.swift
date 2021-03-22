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
  
  func done(data optionalData: Data? = nil, url: String? = nil) -> LayerAcceptanceResults {
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
    
    return done(layerDefinitions: layerDefinitions)
  }
  
  func done(layerDefinitions: [LayerDefinition]) -> LayerAcceptanceResults {
    let single = layerDefinitions.count == 1
    
    let results = layerDefinitions.map({LayerManager.shared.newLayer($0, visible: single)})
    let added = results.filter({$0 != nil}).count
    let updated = layerDefinitions.count - added
    
    DispatchQueue.main.async {
      LayerManager.shared.saveLayers()
      super.done()
    }
    
    return LayerAcceptanceResults(added: added, updated: updated)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct LayerAcceptanceResults {
  let added: Int
  let updated: Int
  
  let accepted: Int
  
  init(added: Int, updated: Int) {
    self.added = added
    self.updated = updated
    
    self.accepted = added + updated
  }
}
