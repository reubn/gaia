import Foundation
import UIKit

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
     
    let decoder = JSONDecoder()
    
    let layerDefintionArrayAttempt = try? decoder.decode([LayerDefinition].self, from: data)
    print("layerDefintionArrayAttempt")
    
    let layerDefinitionSingleAttempt = layerDefintionArrayAttempt ?? {() -> [LayerDefinition]? in
      print("layerDefinitionSingleAttempt")
      guard let decodeAttempt = try? decoder.decode(LayerDefinition.self, from: data) else {
        return nil
      }
      
      return [decodeAttempt]
    }()
    
    let gpxSingleAttempt = layerDefinitionSingleAttempt ?? {() -> [LayerDefinition]? in
      print("gpxSingleAttempt")
      guard let decodeAttempt = GPXParser(withData: data).parsedData(),
            decodeAttempt.tracks.count != 0 else { // check for waymarkers too!!!
        return nil
      }
      
      let layerDefinition = LayerDefinition(gpx: decodeAttempt)
      
      return [layerDefinition]
    }()
    
    let xyzSingleAttempt = gpxSingleAttempt ?? {() -> [LayerDefinition]? in
      print("xyzSingleAttempt")
      guard let url = url,
            ["{x}", "{y}", "{z}"].allSatisfy({url.contains($0)}) else {
        return nil
      }
      
      let layerDefinition = LayerDefinition(xyzURL: url)
      
      return [layerDefinition]
    }()
    
    let layerDefinitions = xyzSingleAttempt ?? []
    
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
        
        LayerManager.shared.show(layer: addedLayer, mutuallyExclusive: true) // if adding a single layer, make it visible
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
