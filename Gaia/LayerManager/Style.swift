import Foundation
import CoreData

class Style {
  let sortedLayers: [Layer]
  
  var needsDarkUI: Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    if(topNonOverlay == nil) {return true}

    return topNonOverlay!.group == "aerial"
  }
  
  var url: URL? {
    Style.toURL(jsonObject: jsonObject)
  }
  
  var jsonObject: StyleJSON {
    let sources = sortedLayers.map {StyleJSON.Source($0 as Layer)}

    return StyleJSON(
      sources: sources.reduce(into: [String: StyleJSON.Source]()) {$0[$1.id] = $1},
      layers: sources.map {StyleJSON.Layer($0 as StyleJSON.Source)}
    )
  }
  
  init(sortedLayers: [Layer]){
    self.sortedLayers = sortedLayers
  }
  
  static func toURL(data: Data) -> URL? {
    do {
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFilename = ProcessInfo().globallyUniqueString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  static func toURL(jsonObject: StyleJSON) -> URL? {
    do {
      let encoder = JSONEncoder()

      return Style.toURL(data: try encoder.encode(jsonObject))
      
    } catch {
      return nil
    }
  }
}

struct StyleJSON: Codable {
  var version = 8
  let sources: [String: Source]
  let layers: [Layer]
  
  struct Source: Codable {
    let id: String
    let name: String
    let group: String
    let groupIndex: Int
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

// Layer from StyleJSON.Source
extension Layer {
  convenience init(_ source: StyleJSON.Source, context: NSManagedObjectContext){
    self.init(context: context)
    
    self.id = source.id
    self.name = source.name
    self.group = source.group
    self.groupIndex = Int16(source.groupIndex)
    self.url = source.tiles[0]
    
    if(source.minzoom != nil) {self.minZoom = String(source.minzoom!)}
    if(source.maxzoom != nil) {self.maxZoom = String(source.maxzoom!)}
    if(source.tileSize != nil) {self.tileSize = String(source.tileSize!)}
    
    self.enabled = false
  }
}

// StyleJSON.Source from Layer
extension StyleJSON.Source {
  init(_ layer: Layer){
    self.init(
      id: layer.id!,
      name: layer.name!,
      group: layer.group!,
      groupIndex: Int(layer.groupIndex),
      type: .raster,
      tiles: [layer.url!],
      minzoom: (layer.minZoom ?? "").isEmpty ? nil : Int(layer.minZoom!),
      maxzoom: (layer.maxZoom ?? "").isEmpty ? nil : Int(layer.maxZoom!),
      tileSize: (layer.tileSize ?? "").isEmpty ? 256 : Int(layer.tileSize!)
    )
  }
}

// StyleJSON.Layer from StyleJSON.Source
extension StyleJSON.Layer {
  init(_ source: StyleJSON.Source){
    self.init(
      id: source.id,
      type: source.type,
      source: source.id,
      minzoom: source.minzoom,
      maxzoom: source.maxzoom
    )
  }
}
