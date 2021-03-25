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
  
  func acceptLayerDefinitions(from optionalData: Data? = nil, url: String? = nil) -> LayerAcceptanceResults? {
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
    
    return acceptLayerDefinitions(from: layerDefinitions)
  }
  
  func acceptLayerDefinitions(from layerDefinitions: [LayerDefinition], methods: [LayerAcceptanceMethod]? = nil) -> LayerAcceptanceResults? {
    if(layerDefinitions.isEmpty){
      return nil
    }
    
    let results = LayerAcceptanceResults(submitted: layerDefinitions.map({LayerManager.shared.accept(layerDefinition: $0, methods: methods)}))
    if(!results.accepted.isEmpty) {
      if results.submitted.count == 1,
         let addedLayer = results.added.first?.layer {
        DispatchQueue.main.async {
          LayerManager.shared.show(layer: addedLayer, mutuallyExclusive: true) // if adding a single layer, make it visible
        }
      } else {
        LayerManager.shared.save()
      }
    }
    
    return results
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
