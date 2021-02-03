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
  @NSManaged private var styleJSONString: String
  
  var styleJSON: StyleJSON {
    get {
      let decoder = JSONDecoder()
      
      let data = styleJSONString.data(using: .utf8)
      
      return try! decoder.decode(StyleJSON.self, from: data!)
    }
    
    set {
      let encoder = JSONEncoder()
      
      styleJSONString = String(data: try! encoder.encode(newValue), encoding: .utf8)!
    }
  }
}


extension Layer: Identifiable {}

// Layer from LayerDefinition
extension Layer {
  convenience init(_ layerDefinition: LayerDefinition, context: NSManagedObjectContext){
    self.init(context: context)

    self.id = layerDefinition.metadata.id
    self.name = layerDefinition.metadata.name
    self.group = layerDefinition.metadata.group
    self.groupIndex = Int16(layerDefinition.metadata.groupIndex)
    
    self.styleJSON = layerDefinition.styleJSON

    self.enabled = false
  }
}
