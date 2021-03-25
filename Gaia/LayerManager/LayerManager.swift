import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  
  var magicLayers: [Layer]?

  let multicastCompositeStyleDidChangeDelegate = MulticastDelegate<(LayerManagerDelegate)>()

  lazy var groups = [
    LayerGroup(id: "uncategorised", name: "Uncategorised", colour: .systemPurple),
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(id: "base", name: "Base Maps", colour: .systemBlue),
    LayerGroup(id: "historic", name: "Historic", colour: .brown)
  ]
  
  var layers: [Layer] = []

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
      return a.enabled // sort disabled layers below within same group
    }
    
    return layerSortingFunction(a: LayerDefinition.Metadata(layer: a), b: LayerDefinition.Metadata(layer: b))
  }
  
  func layerSortingFunction(a: LayerDefinition.Metadata, b: LayerDefinition.Metadata) -> Bool {
    if(a.group != b.group) {
      return groups.firstIndex(where: {layerGroup in a.group == layerGroup.id}) ?? 0 < groups.firstIndex(where: {layerGroup in b.group == layerGroup.id}) ?? 0
    }
    
    if(a.groupIndex != b.groupIndex) {return a.groupIndex < b.groupIndex}
    
    return a.name < b.name
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
      layers = try managedContext.fetch(fetchRequest) as! [Layer]
      let previous = _compositeStyle
      
      _compositeStyle = nil // flush cache
      multicastCompositeStyleDidChangeDelegate.invoke(invocation: {$0.compositeStyleDidChange(to: compositeStyle, from: previous)})
    } catch {print("Failed")}
  }
  
  func save(){
    do {
      try managedContext.save()
    
      reloadData()
    } catch {
        print("saving error :", error)
    }
  }
  
  func accept(layerDefinition: LayerDefinition, methods: [LayerAcceptanceMethod]? = nil) -> LayerAcceptanceResult {
    let acceptanceMethods = (methods?.isEmpty ?? false ? nil : methods) ?? [.update(), .add]
    
    var error: LayerAcceptanceResult = .error(.unexplained)
 
    for method in acceptanceMethods {
      switch method {
        case .update(let required):
         
          // updating specified layer: required != nil && existingWithRequiredId != nil && layerDefinition.metadata.id == required!.id
          // importing and override: ||
          
          let existingWithEditedId = layers.first(where: {$0.id == layerDefinition.metadata.id})
          
          if(required != nil){
            if let existing = layers.first(where: {$0.id == required!.id}),
              existingWithEditedId == nil || existingWithEditedId == existing {
              existing.update(layerDefinition)
              print("yes we are updating required", existing)
              
              return .accepted(method)
            }
            
            error = .error(.layerExistsWithId(layerDefinition.metadata.id))
          } else {
            if let existing = existingWithEditedId {
              existing.update(layerDefinition)
              print("yes we are updating edited", existing)
              
              return .accepted(method)
            }
            
            error = .error(.noLayerExistsWithId(layerDefinition.metadata.id))
          }
        case .add:
          let existing = layers.first(where: {$0.id == layerDefinition.metadata.id})
          
          if(existing == nil) {
            print("yes we are adding")
            let layer = Layer(layerDefinition, context: managedContext)
            return .accepted(method, layer: layer)
          }
          
          error = .error(.layerExistsWithId(layerDefinition.metadata.id))
      }
    }
    print("fuck nothing happened")
    
    return error
  }
  
  func remove(layer: Layer){
    managedContext.delete(layer)
    
    save()
  }

  @discardableResult func show(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(!layer.isOpaque || !mutuallyExclusive) {
      layer.visible = true
    } else {
      for _layer in layers {
        if(_layer.isOpaque) {
          _layer.visible = _layer == layer
        }
      }
    }

    save()
    
    return true
  }

  @discardableResult func hide(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    if(!layer.isOpaque || !mutuallyExclusive || visibleLayers.filter({$0.isOpaque}).count > 1) {
      layer.visible = false
      save()
      
      return true
    }
    
    return false
  }
  
  func show(layers _layers: [Layer?]) {
    for layer in _layers {
      layer?.visible = true
    }
    
    save()
  }
  
  func hide(layers _layers: [Layer?]) {
    for layer in _layers {
      layer?.visible = false
    }
    
    save()
  }
  
  func filter(_ shouldBeEnabled: (Layer) -> Bool){
    for layer in layers {
      layer.visible = shouldBeEnabled(layer)
    }
    
    save()
  }

  public func getLayers(layerGroup: LayerGroup) -> [Layer] {
    layers.filter({$0.group == layerGroup.id}).sorted(by: layerSortingFunction)
  }

  public func magic() -> (count: Int, restore: Bool) {
    let visibleOverlayLayers = layers.filter({$0.visible && !$0.isOpaque})
    if(!visibleOverlayLayers.isEmpty) {
      // visible overlays, capture
      magicLayers = visibleOverlayLayers

      // and hide them
      hide(layers: visibleOverlayLayers)
      
      return (count: visibleOverlayLayers.count, restore: false)
    } else {
      // no visible overlays, restore. Either captured layers, or topmost overlay layer
      let layersToRestore: [Layer?] = magicLayers ?? [layers.sorted(by: layerSortingFunction).first(where: {!$0.isOpaque})]
      
      // and show them
      show(layers: layersToRestore)

      magicLayers = nil
      
      return (count: layersToRestore.count, restore: true)
    }
  }
  
  public func magicPinned(forward: Bool) -> Layer? {
    let interestedLayers = pinnedLayers.filter({$0.isOpaque}).sorted(by: layerSortingFunction)
    
    if(interestedLayers.isEmpty) {return nil}
    
    let visiblePinnedLayers = interestedLayers.filter({$0.visible})
    let topVisiblePinnedLayer = visiblePinnedLayers.first
    
    switch visiblePinnedLayers.count {
    case 0: // show the first pinned
      let nextLayer = interestedLayers.first!
      show(layer: nextLayer, mutuallyExclusive: true)
      
      return nextLayer
    case 1: // move to next pinned, or wrap around
      let currentIndex = interestedLayers.firstIndex(of: topVisiblePinnedLayer!)!
      let nextIndex = forward
        ? interestedLayers.index(after: currentIndex, wrap: true)
        : interestedLayers.index(before: currentIndex, wrap: true)
      
      let nextLayer = interestedLayers[nextIndex]
      show(layer: nextLayer, mutuallyExclusive: true)
      
      return nextLayer
    default: // handle more than one pinned visible
      return nil
    }
  }
  
  static let shared = LayerManager()
}

protocol LayerManagerDelegate {
  func compositeStyleDidChange(to: CompositeStyle, from: CompositeStyle?)
}
