import Foundation
import CoreData

@objc(Layer)
public class Layer: NSManagedObject {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Layer> {
      return NSFetchRequest<Layer>(entityName: "Layer")
  }

  @NSManaged public var enabled: Bool
  @NSManaged public var group: String
  @NSManaged public var groupIndex: Int16
  @NSManaged public var id: String
  @NSManaged public var name: String
  @NSManaged private var styleString: String
  
  var style: Style {
    get {
      let decoder = JSONDecoder()
      
      let data = styleString.data(using: .utf8)
      
      return try! decoder.decode(Style.self, from: data!)
    }
    
    set {
      let encoder = JSONEncoder()
      
      styleString = String(data: try! encoder.encode(newValue), encoding: .utf8)!
    }
  }
}


extension Layer: Identifiable {}

// Layer from LayerDefinition
extension Layer {
  convenience init(_ layerDefinition: LayerDefinition, context: NSManagedObjectContext){
    self.init(context: context)
    
    self.enabled = false
    
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
