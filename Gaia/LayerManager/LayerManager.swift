import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  var delegate: LayerManagerDelegate?
  var groups: [String: [Layer]]?
  var magicLayers: [Layer]?

  let multicastStyleDidChangeDelegate = MulticastDelegate<(LayerManagerDelegate)>()

  let layerGroups = [
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(id: "base", name: "Base Maps", colour: .systemBlue)
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

    reloadData()
  }

  func layerSortingFunction(a: Layer, b: Layer) -> Bool {
    if(a.group! != b.group!) {
      return layerGroups.firstIndex(where: {layerGroup in a.group! == layerGroup.id}) ?? 0 > layerGroups.firstIndex(where: {layerGroup in b.group! == layerGroup.id}) ?? 0
    }
    
    if(a.groupIndex != b.groupIndex) {return a.groupIndex > b.groupIndex}
    
    return a.name! > b.name!
  }

  func reloadData() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Layer")

    do {
      let results = try managedContext.fetch(fetchRequest) as! [Layer]

      let unorderedGroups = Dictionary(grouping: results) { (obj) -> String in
        return obj.group!
      }

      groups = unorderedGroups.mapValues({
        $0.sorted(by: layerSortingFunction)
      })
      
      informDelegates()

    } catch {print("Failed")}
  }

  func informDelegates(){
    multicastStyleDidChangeDelegate.invoke(invocation: {$0.styleDidChange(style: style)})
  }
  
  func saveLayers(){
    do {
        try managedContext.save()
      
        reloadData()
    } catch {
        print("saving error :", error)
    }
  }
  func removeLayer(layer: Layer){
    managedContext.delete(layer)
    
    saveLayers()
  }

  func enableLayer(layer: Layer, mutuallyExclusive: Bool) {
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
  }

  func disableLayer(layer: Layer) {
    layer.enabled = false

    saveLayers()
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
        disableLayer(layer: $0)
      })
    } else {
      // no active overlays, restore
      (magicLayers ?? overlayLayers).forEach({
        enableLayer(layer: $0, mutuallyExclusive: false)
      })

      magicLayers = nil
    }
  }
  
  var style: Style {
    get {
      Style(sortedLayers: sortedLayers)
    }
  }
}

struct LayerGroup {
  let id: String
  let name: String
  let colour: UIColor
}


protocol LayerManagerDelegate {
  func styleDidChange(style: Style)
}
