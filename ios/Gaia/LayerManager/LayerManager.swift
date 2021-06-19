import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  
  var magicLayers: [Layer]?

  let multicastCompositeStyleDidChangeDelegate = MulticastDelegate<(LayerManagerDelegate)>()

  lazy var groups = [
    LayerGroup(id: "gpx", name: "GPX", colour: .systemTeal, icon: "point.fill.topleft.down.curvedto.point.fill.bottomright.up"),
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink, icon: "highlighter"),
    LayerGroup(id: "aerial", name: "Aerial", colour: .systemGreen, icon: "airplane"),
    LayerGroup(id: "base", name: "Base", colour: .systemBlue, icon: "map"),
    LayerGroup(id: "historic", name: "Historic", colour: .brown, icon: "clock.arrow.circlepath"),
  ]
  
  lazy var groupIds = groups.map({$0.id})
  
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
  
  var ungroupedLayers: [Layer]{
    get {
      layers.filter({!groupIds.contains($0.group)})
    }
  }

  private var _compositeStyle: CompositeStyle?
  
  var compositeStyle: CompositeStyle {
    get {
      if(_compositeStyle != nil) {
        return _compositeStyle!
      }
      
      _compositeStyle = CompositeStyle(sortedLayers: visibleLayers.sorted(by: layerSortingFunction))
      
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
    if(a.isOpaque != b.isOpaque) {
      return b.isOpaque
    }
    
    if(a.group != b.group) {
      return groups.firstIndex(where: {layerGroup in a.group == layerGroup.id}) ?? 0 < groups.firstIndex(where: {layerGroup in b.group == layerGroup.id}) ?? 0
    }
    
    if(a.enabled != b.enabled) {
      return a.enabled // sort disabled layers below within same group
    }
    
    if(a.groupIndex != b.groupIndex) {
      return a.groupIndex < b.groupIndex
    }
    
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
    interfacedSourcesCache.removeValue(forKey: layer.style.hashValue)
    interfacedLayersCache.removeValue(forKey: layer.style.hashValue)
    
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
  
  func filter(_ shouldBeVisible: (Layer) -> Bool){
    for layer in layers {
      layer.visible = shouldBeVisible(layer)
    }
    
    save()
  }

  public func getLayers(layerGroup: LayerGroup) -> [Layer] {
    layers.filter({$0.group == layerGroup.id}).sorted(by: layerSortingFunction)
  }

  public func magic(bounds: MGLCoordinateBounds) -> (count: Int, restore: Bool) {
    let visibleOverlayLayers = layers.filter({
      $0.visible
      && $0.enabled
      && !$0.isOpaque
      && (
        $0.style.bounds.superbound == nil
        || bounds.intersects(with: $0.style.bounds.superbound!)
      )
    })
    
    if(!visibleOverlayLayers.isEmpty) {
      // visible overlays, capture
      magicLayers = visibleOverlayLayers

      // and hide them
      hide(layers: visibleOverlayLayers)
      
      return (count: visibleOverlayLayers.count, restore: false)
    } else {
      //  no visible overlays
      let visibleMagicLayers = magicLayers?.filter({$0.style.bounds.superbound == nil || bounds.intersects(with: $0.style.bounds.superbound!)}) ?? []
    
      let layersToRestore: [Layer?] = {
        if(!visibleMagicLayers.isEmpty) {
          // restore captured layers in bounds
          return visibleMagicLayers
        }
        
        let transparent = layers.filter({!$0.isOpaque && $0.enabled}).sorted(by: layerSortingFunction)
        
        return [
          // or top most overlay with and in bounds
          transparent.first(where: {$0.style.bounds.superbound != nil && bounds.intersects(with: $0.style.bounds.superbound!)})
            ?? transparent.first(where: {$0.style.bounds.superbound == nil}) // or top most global overlay
        ]
      }()
        
      
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
