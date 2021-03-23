import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  
  var groups: [String: [Layer]]?
  var magicLayers: [Layer]?

  let multicastCompositeStyleDidChangeDelegate = MulticastDelegate<(LayerManagerDelegate)>()

  lazy var layerGroups = [
    LayerGroup(id: "uncategorised", name: "Uncategorised", colour: .systemPurple),
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(id: "base", name: "Base Maps", colour: .systemBlue),
    LayerGroup(id: "historic", name: "Historic", colour: .brown)
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

  var visibleLayers: [Layer]{
    get {
      layers.filter({$0.visible})
    }
  }
  
  var pinnedLayers: [Layer]{
    get {
      layers.filter({$0.pinned})
    }
  }
  
  var disabledLayers: [Layer]{
    get {
      layers.filter({!$0.enabled})
    }
  }

  var sortedLayers: [Layer]{
    get {
      visibleLayers.sorted(by: layerSortingFunction)
    }
  }
  
  private var _compositeStyle: CompositeStyle?
  
  var compositeStyle: CompositeStyle {
    get {
      if(_compositeStyle != nil) {
        return _compositeStyle!
      }
      
      _compositeStyle = CompositeStyle(sortedLayers: sortedLayers)
      
      return _compositeStyle!
    }
  }
  
  init(){
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    self.managedContext = appDelegate!.persistentContainer.viewContext
    
//    clearData()
    reloadData()
  }

  func layerSortingFunction(a: Layer, b: Layer) -> Bool {
    if(a.group == b.group && a.enabled != b.enabled) {
      return b.enabled // sort disabled layers below within same group
    }
    
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
      
      let previous = _compositeStyle
      
      _compositeStyle = nil // flush cache
      multicastCompositeStyleDidChangeDelegate.invoke(invocation: {$0.compositeStyleDidChange(to: compositeStyle, from: previous)})
    } catch {print("Failed")}
  }
  
  func saveLayers(){
    do {
        try managedContext.save()
      
        reloadData()
    } catch {
        print("saving error :", error)
    }
  }
  
  func newLayer(_ layerDefinition: LayerDefinition, visible: Bool = false) -> Layer? {
    if let existing = layers.first(where: {$0.id == layerDefinition.metadata.id}) {
      print("updating definition for", existing.id)
      
      existing.update(layerDefinition)
      
      if(visible){
        existing.visible = true
      }
      
      return nil
    }
    
    let layer = Layer(layerDefinition, context: managedContext, visible: visible)

    return layer
  }
  
  func removeLayer(layer: Layer){
    managedContext.delete(layer)
    
    saveLayers()
  }

  @discardableResult func enableLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(!layer.isOpaque || !mutuallyExclusive) {
      layer.visible = true
    } else {
      for _layer in layers {
        if(_layer.isOpaque) {
          _layer.visible = _layer == layer
        }
      }
    }

    saveLayers()
    
    return true
  }

  @discardableResult func disableLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(!layer.isOpaque || !mutuallyExclusive || visibleLayers.filter({$0.isOpaque}).count > 1) {
      layer.visible = false
      saveLayers()
      
      return true
    }
    
    return false
  }
  
  func filterLayers(_ shouldBeEnabled: (Layer) -> Bool){
    for layer in layers {
      layer.visible = shouldBeEnabled(layer)
    }
    
    saveLayers()
  }

  public func getLayers(layerGroup: LayerGroup) -> [Layer] {
    groups![layerGroup.id] ?? []
  }

  public func magic() -> (count: Int, restore: Bool) {
    let overlayGroup = layerGroups.first(where: {$0.id == "overlay"})!
    let overlayLayers = getLayers(layerGroup: overlayGroup)

    let visibleOverlayLayers = overlayLayers.filter({$0.visible})
    if(visibleOverlayLayers.count > 0) {
      // visible overlays, capture
      magicLayers = visibleOverlayLayers

      // and hide them
      visibleOverlayLayers.forEach({
        disableLayer(layer: $0, mutuallyExclusive: false)
      })
      
      return (count: visibleOverlayLayers.count, restore: false)
    } else {
      // no visible overlays, restore
      let layersToRestore = magicLayers ?? overlayLayers.filter({$0.enabled})
      layersToRestore.forEach({
        enableLayer(layer: $0, mutuallyExclusive: false)
      })

      magicLayers = nil
      
      return (count: layersToRestore.count, restore: true)
    }
  }
  
  public func magicPinned(forward: Bool) -> Layer? {
    let interestedLayers = pinnedLayers.filter({$0.isOpaque}).sorted(by: layerSortingFunction).reversed()
    
    if(interestedLayers.isEmpty) {return nil}
    
    let visiblePinnedLayers = interestedLayers.filter({$0.visible})
    let topVisiblePinnedLayer = visiblePinnedLayers.first
    
    switch visiblePinnedLayers.count {
    case 0: // enable the first pinned
      let nextLayer = interestedLayers.first!
      enableLayer(layer: nextLayer, mutuallyExclusive: true)
      
      return nextLayer
    case 1: // move to next pinned, or wrap around
      let currentIndex = interestedLayers.firstIndex(of: topVisiblePinnedLayer!)!
      let nextIndex = forward
        ? interestedLayers.index(after: currentIndex, wrap: true)
        : interestedLayers.index(before: currentIndex, wrap: true)
      
      let nextLayer = interestedLayers[nextIndex]
      enableLayer(layer: nextLayer, mutuallyExclusive: true)
      
      return nextLayer
    default: // handle more than one pinned visible
      return nil
    }
  }
  
  static let shared = LayerManager()
}

struct LayerGroup {
  let id: String
  let name: String
  let colour: UIColor
  
  var selectionFunction: (() -> [Layer])? = nil
  
  func getLayers() -> [Layer] {
    if(selectionFunction == nil) {
      return LayerManager.shared.getLayers(layerGroup: self)
    } else {
      return selectionFunction!()
    }
  }
}

protocol LayerManagerDelegate {
  func compositeStyleDidChange(to: CompositeStyle, from: CompositeStyle?)
}
