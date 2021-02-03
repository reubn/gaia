import Foundation

struct StyleJSON: Codable {
  var version = 8
  let sources: [String: Source]
  let layers: [Layer]

  struct Source: Codable {
    let type: LayerType
    let tiles: [String]

    let minzoom: Int?
    let maxzoom: Int?
    let tileSize: Int?
  }
  
  struct Layer: Codable {
    let id: String
    let type: LayerType
    let source: String

    let minzoom: Int?
    let maxzoom: Int?
  }
  
  enum LayerType: String, Codable {
    case vector, raster
  }
}
