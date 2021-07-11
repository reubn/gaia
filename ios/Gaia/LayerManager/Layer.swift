import Foundation
import CoreData

import ZippyJSON

@objc(Layer)
public class Layer: NSManagedObject {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Layer> {
      return NSFetchRequest<Layer>(entityName: "Layer")
  }

  @NSManaged public var visible: Bool
  @NSManaged public var enabled: Bool
  @NSManaged public var pinned: Bool
  @NSManaged public var quickToggle: Bool
  @NSManaged public var group: String
  @NSManaged public var groupIndex: Int16
  @NSManaged public var id: String
  @NSManaged public var name: String
  @NSManaged public var attribution: String?
  @NSManaged public var overrideUIMode: String?
  
  @NSManaged private var styleString: String
  
  var needsDarkUI: Bool {
    switch overrideUIMode {
      case "dark": return true
      case "light": return false
      default: return group == "aerial" || group == "overlay"
    }
  }
  
  var isOpaque: Bool {
    switch group {
      case "gpx", "overlay": return false
      default: return style.opacity == 1
    }
  }
  
  private var _style: Style?
  
  var style: Style {
    get {
      if(_style != nil) {
        return _style!
      }
      
      let decoder = ZippyJSONDecoder()
      
      let data = styleString.data(using: .utf8)
      
      _style = try! decoder.decode(Style.self, from: data!)
      
      return _style!
    }
    
    set {
      let encoder = JSONEncoder()
      
      _style = newValue
      styleString = String(data: try! encoder.encode(newValue), encoding: .utf8)!
    }
  }
}

// Layer from LayerDefinition
extension Layer {
  convenience init(_ layerDefinition: LayerDefinition, context: NSManagedObjectContext){
    self.init(context: context)
    
    self.update(layerDefinition)
  }
  
  func update(_ layerDefinition: LayerDefinition){
    self.id = layerDefinition.metadata.id
    self.name = layerDefinition.metadata.name
    self.group = layerDefinition.metadata.group
    self.overrideUIMode = layerDefinition.metadata.overrideUIMode
    self.attribution = layerDefinition.metadata.attribution
    
    if let user = layerDefinition.user {
      self.groupIndex = Int16(user.groupIndex)
      
      self.pinned = user.pinned
      self.enabled = user.enabled
      self.quickToggle = user.quickToggle
    }
    
    self.style = layerDefinition.style
  }
}
