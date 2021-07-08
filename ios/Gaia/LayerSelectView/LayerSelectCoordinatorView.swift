import Foundation
import UIKit

import Mapbox
import CoreGPX
import ZippyJSON


class LayerSelectCoordinatorView: CoordinatorView, PanelDelegate {
  unowned let panelViewController: LayerSelectPanelViewController
  
  init(panelViewController: LayerSelectPanelViewController){
    self.panelViewController = panelViewController
    
    super.init()
    
    self.panelViewController.panelDelegate = self

    story = [
      LayerSelectHome(coordinatorView: self),
      LayerSelectImport(coordinatorView: self),
      LayerSelectEdit(coordinatorView: self)
    ]
    
    super.ready()
  }
  
  func acceptLayerDefinitions(from optionalData: Data? = nil, url: String? = nil) -> LayerAcceptanceResults? {
    let data = optionalData ?? Data()
     
    let decoder = ZippyJSONDecoder()
    
    let layerDefintionArrayAttempt = try? decoder.decode([LayerDefinition].self, from: data)
    print("layerDefintionArrayAttempt")
    
    let layerDefinitionSingleAttempt = layerDefintionArrayAttempt ?? {() -> [LayerDefinition]? in
      print("layerDefinitionSingleAttempt")
      guard let decodeAttempt = try? decoder.decode(LayerDefinition.self, from: data) else {
        return nil
      }
      
      return [decodeAttempt]
    }()
    
    let styleSingleAttempt = layerDefinitionSingleAttempt ?? {() -> [LayerDefinition]? in
      print("styleSingleAttempt")
      guard let decodeAttempt = try? decoder.decode(Style.self, from: data) else {
        return nil
      }
      
      let layerDefinition = LayerDefinition(style: decodeAttempt)
      
      return [layerDefinition]
    }()
    
    let geoJSONSingleAttempt = styleSingleAttempt ?? {() -> [LayerDefinition]? in
      print("geoJSONSingleAttempt")
      guard let decodeAttempt = try? decoder.decode(AnyCodable.self, from: data),
            geoJSON(appearsToBe: decodeAttempt) else {
        return nil
      }
      
      let layerDefinition = LayerDefinition(geoJSON: decodeAttempt)
      
      return [layerDefinition]
    }()
    
    let gpxSingleAttempt = geoJSONSingleAttempt ?? {() -> [LayerDefinition]? in
      print("gpxSingleAttempt")
      guard let decodeAttempt = GPXParser(withData: data).parsedData(),
            decodeAttempt.tracks.count + decodeAttempt.waypoints.count != 0 else {
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
  
  func panelDidDisappear() {
    if let current = story[storyPosition] as? PanelDelegate {
      current.panelDidDisappear()
    }
    
    story[storyPosition].viewWillExit()
  }
  
  func panelDidMove() {
    if let current = story[storyPosition] as? PanelDelegate {
      current.panelDidMove()
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
