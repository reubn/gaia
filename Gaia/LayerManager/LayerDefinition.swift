import Foundation

struct LayerDefinition: Codable {
  let metadata: Metadata
  
  let styleJSON: StyleJSON
  
  struct Metadata: Codable {
    let id: String
    let name: String
    let group: String
    let groupIndex: Int
  }
}


extension LayerDefinition.Metadata {
  init(_ layer: Layer){
    self.init(
      id: layer.id,
      name: layer.name,
      group: layer.group,
      groupIndex: Int(layer.groupIndex)
    )
  }
}

extension LayerDefinition {
  init(_ layer: Layer){
    self.init(
      metadata: Metadata(layer),
      styleJSON: layer.styleJSON
    )
  }
}
