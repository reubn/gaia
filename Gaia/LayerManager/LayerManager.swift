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
  
  func saveLayers(){
    do {
        try managedContext.save()
      
        reloadData()
    } catch {
        print("saving error :", error)
    }
  }
  
  func acceptLayer(_ layerDefinition: LayerDefinition, methods: [LayerAcceptanceMethod]? = nil) -> LayerAcceptanceResult {
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
  
  func removeLayer(layer: Layer){
    managedContext.delete(layer)
    
    saveLayers()
  }

  @discardableResult func showLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
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

  @discardableResult func hideLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
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
    layers.filter({$0.group == layerGroup.id}).sorted(by: layerSortingFunction)
  }

  public func magic() -> (count: Int, restore: Bool) {
    let visibleOverlayLayers = layers.filter({$0.visible && !$0.isOpaque})
    if(!visibleOverlayLayers.isEmpty) {
      // visible overlays, capture
      magicLayers = visibleOverlayLayers

      // and hide them
      visibleOverlayLayers.forEach({
        hideLayer(layer: $0, mutuallyExclusive: false)
      })
      
      return (count: visibleOverlayLayers.count, restore: false)
    } else {
      // no visible overlays, restore. Either captured layers, or topmost overlay layer
      let layersToRestore: [Layer?] = magicLayers ?? [layers.sorted(by: layerSortingFunction).first(where: {!$0.isOpaque})]
      layersToRestore.forEach({
        if($0 != nil){
          showLayer(layer: $0!, mutuallyExclusive: false)
        }
      })

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
      showLayer(layer: nextLayer, mutuallyExclusive: true)
      
      return nextLayer
    case 1: // move to next pinned, or wrap around
      let currentIndex = interestedLayers.firstIndex(of: topVisiblePinnedLayer!)!
      let nextIndex = forward
        ? interestedLayers.index(after: currentIndex, wrap: true)
        : interestedLayers.index(before: currentIndex, wrap: true)
      
      let nextLayer = interestedLayers[nextIndex]
      showLayer(layer: nextLayer, mutuallyExclusive: true)
      
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


enum LayerAcceptanceMethod {
  case add
  case update(Layer? = nil)
}

struct LayerAcceptanceResult {
  let method: LayerAcceptanceMethod?
  let error: LayerAcceptanceError?
  
  let layer: Layer?
  
  var accepted: Bool {
    error == nil
  }
  
  static func accepted(_ method: LayerAcceptanceMethod, layer: Layer? = nil) -> Self {
    self.init(method: method, error: nil, layer: layer)
  }
  
  static func error(_ error: LayerAcceptanceError) -> Self {
    self.init(method: nil, error: error, layer: nil)
  }
}

struct LayerAcceptanceResults {
  let submitted: [LayerAcceptanceResult]
  
  var accepted: [LayerAcceptanceResult] {
    submitted.filter({$0.accepted})
  }
  
  var rejected: [LayerAcceptanceResult] {
    submitted.filter({!$0.accepted})
  }
  
  var added: [LayerAcceptanceResult] {
    accepted.filter({if case .add = $0.method {return true} else {return false}})
  }
  
  var updated: [LayerAcceptanceResult] {
    accepted.filter({if case .update = $0.method {return true} else {return false}})
  }
}

enum LayerAcceptanceError {
  case layerExistsWithId(String)
  case noLayerExistsWithId(String)

  case unexplained
}
