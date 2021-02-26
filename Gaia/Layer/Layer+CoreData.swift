import Foundation
import CoreData

@objc(Layer)
public class Layer: NSManagedObject {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Layer> {
      return NSFetchRequest<Layer>(entityName: "Layer")
  }

  @NSManaged public var visible: Bool
  @NSManaged public var enabled: Bool
  @NSManaged public var favourite: Bool
  @NSManaged public var group: String
  @NSManaged public var groupIndex: Int16
  @NSManaged public var id: String
  @NSManaged public var name: String
  @NSManaged private var styleString: String
  
  private var _style: Style?
  
  var style: Style {
    get {
      if(_style != nil) {
        return _style!
      }
      
      let decoder = JSONDecoder()
      
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


extension Layer: Identifiable {}

// Layer from LayerDefinition
extension Layer {
  convenience init(_ layerDefinition: LayerDefinition, context: NSManagedObjectContext, visible: Bool = false, favourite: Bool = false, enabled: Bool = true){
    self.init(context: context)
    
    self.visible = visible
    self.favourite = favourite
    self.enabled = enabled
    
    self.update(layerDefinition)
  }
  
  func update(_ layerDefinition: LayerDefinition){
    self.id = layerDefinition.metadata.id
    self.name = layerDefinition.metadata.name
    self.group = layerDefinition.metadata.group
    self.groupIndex = Int16(layerDefinition.metadata.groupIndex)
    
    self.style = layerDefinition.style
  }
}
