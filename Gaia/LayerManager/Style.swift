import Foundation

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
    let sources = sortedLayers.reduce(into: [String: StyleJSON.Source]()) {
      let incoming = $1 as Layer
      $0[$1.id!] = StyleJSON.Source(
        name: incoming.name,
        type: .raster,
        tiles: [incoming.url!],
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!),
        tileSize: (incoming.tileSize ?? "").isEmpty ? 256 : Int(incoming.tileSize!)
      )
    }

    let layers: [StyleJSON.Layer] = sortedLayers.map {
      let incoming = $0 as Layer

      return StyleJSON.Layer(
        id: incoming.id!,
        type: .raster,
        source: incoming.id!,
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!)
      )
    }

    return StyleJSON(sources: sources, layers: layers)
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
    let name: String?
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
