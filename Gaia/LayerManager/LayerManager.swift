import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  var delegate: LayerManagerDelegate?
  var groups: [String: [Layer]]?
  var magicLayers: [Layer]?

  let multicastCompositeStyleDidChangeDelegate = MulticastDelegate<(LayerManagerDelegate)>()

  lazy var layerGroups = [
    LayerGroup(layerManager: self, id: "uncategorised", name: "Uncategorised", colour: .systemPurple),
    LayerGroup(layerManager: self, id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(layerManager: self, id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(layerManager: self, id: "base", name: "Base Maps", colour: .systemBlue),
    LayerGroup(layerManager: self, id: "historic", name: "Historic", colour: .systemIndigo)
  ]
  
  var layers: [Layer]{
    get {
      var layers: [Layer] = []

      for (_, group) in groups! {
        layers.append(contentsOf: group)
      }

      return layers
    }
  }

  var activeLayers: [Layer]{
    get {
      layers.filter({$0.enabled})
    }
  }

  var sortedLayers: [Layer]{
    get {
      activeLayers.sorted(by: layerSortingFunction)
    }
  }
  
  init(){
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    self.managedContext = appDelegate!.persistentContainer.viewContext
    
//    clearData()
    reloadData()
  }

  func layerSortingFunction(a: Layer, b: Layer) -> Bool {
    return layerSortingFunction(a: LayerDefinition.Metadata(layer: a), b: LayerDefinition.Metadata(layer: b))
  }
  
  func layerSortingFunction(a: LayerDefinition.Metadata, b: LayerDefinition.Metadata) -> Bool {
    if(a.group != b.group) {
      return layerGroups.firstIndex(where: {layerGroup in a.group == layerGroup.id}) ?? 0 > layerGroups.firstIndex(where: {layerGroup in b.group == layerGroup.id}) ?? 0
    }
    
    if(a.groupIndex != b.groupIndex) {return a.groupIndex > b.groupIndex}
    
    return a.name > b.name
  }
  
  func clearData(){
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Layer")
      let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

      do {
        try managedContext.execute(batchDeleteRequest)
      } catch {
          print("Detele all data in error :", error)
      }
    }

  func reloadData() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Layer")

    do {
      let results = try managedContext.fetch(fetchRequest) as! [Layer]

      let unorderedGroups = Dictionary(grouping: results) { (obj) -> String in
        return obj.group
      }

      groups = unorderedGroups.mapValues({
        $0.sorted(by: layerSortingFunction)
      })
      
      informDelegates()

    } catch {print("Failed")}
  }

  func informDelegates(){
    multicastCompositeStyleDidChangeDelegate.invoke(invocation: {$0.compositeStyleDidChange(compositeStyle: compositeStyle)})
  }
  
  func saveLayers(){
    do {
        try managedContext.save()
      
        reloadData()
    } catch {
        print("saving error :", error)
    }
  }
  
  func newLayer(_ layerDefinition: LayerDefinition, enabled: Bool = false) -> Layer? {
    if(layers.contains(where: {$0.id == layerDefinition.metadata.id})) {return nil}
    
    let layer = Layer(layerDefinition, context: managedContext, enabled: enabled)

    return layer
  }
  
  func removeLayer(layer: Layer){
    managedContext.delete(layer)
    
    saveLayers()
  }

  @discardableResult func enableLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(layer.group == "overlay" || !mutuallyExclusive) {
      layer.enabled = true
    } else {
      for _layer in layers {
        if(_layer.group != "overlay") {
          _layer.enabled = _layer == layer
        }
      }
    }

    saveLayers()
    
    return true
  }

  @discardableResult func disableLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(layer.group == "overlay" || !mutuallyExclusive || activeLayers.filter({$0.group != "overlay"}).count > 1) {
      layer.enabled = false
      saveLayers()
      
      return true
    }
    
    return false
  }
  
  func filterLayers(_ shouldBeEnabled: (Layer) -> Bool){
    for layer in layers {
      layer.enabled = shouldBeEnabled(layer)
    }
    
    saveLayers()
  }

  public func getLayers(layerGroup: LayerGroup) -> [Layer] {
    groups![layerGroup.id] ?? []
  }

  public func magic(){
    let overlayGroup = layerGroups.first(where: {$0.id == "overlay"})!
    let overlayLayers = getLayers(layerGroup: overlayGroup)

    let activeOverlayLayers = overlayLayers.filter({$0.enabled})
    if(activeOverlayLayers.count > 0) {
      // active overlays, capture
      magicLayers = activeOverlayLayers

      // and hide them
      activeOverlayLayers.forEach({
        disableLayer(layer: $0, mutuallyExclusive: false)
      })
    } else {
      // no active overlays, restore
      (magicLayers ?? overlayLayers).forEach({
        enableLayer(layer: $0, mutuallyExclusive: false)
      })

      magicLayers = nil
    }
  }
  
  var compositeStyle: CompositeStyle {
    get {
      CompositeStyle(sortedLayers: sortedLayers)
    }
  }
}

struct LayerGroup {
  unowned let layerManager: LayerManager
  let id: String
  let name: String
  let colour: UIColor
  
  var selectionFunction: ((LayerManager) -> [Layer])? = nil
  
  func getLayers() -> [Layer] {
    if(selectionFunction == nil) {
      return layerManager.getLayers(layerGroup: self)
    } else {
      return selectionFunction!(layerManager)
    }
  }
}


protocol LayerManagerDelegate {
  func compositeStyleDidChange(compositeStyle: CompositeStyle)
}
