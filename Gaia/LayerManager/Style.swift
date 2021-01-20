import Foundation

class Style {
  let sortedLayers: [Layer]
  
  init(sortedLayers: [Layer]){
    self.sortedLayers = sortedLayers
  }
  
  var url: URL? {
    do {
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFilename = ProcessInfo().globallyUniqueString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try json!.data(using: .utf8)!.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  var json: String? {
    let layerSourcesJSON = sortedLayers.reduce(into: [String: LayerSourceJSON]()) {
      let incoming = $1 as Layer
      $0[$1.id!] = LayerSourceJSON(
        type: LayerTypeJSON.raster,
        tiles: [incoming.url!],
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!),
        tileSize: (incoming.tileSize ?? "").isEmpty ? 256 : Int(incoming.tileSize!)
      )
    }

    let layerLayersJSON: [LayerLayerJSON] = sortedLayers.map {
      let incoming = $0 as Layer

      return LayerLayerJSON(
        id: incoming.id!,
        type: LayerTypeJSON.raster,
        source: incoming.id!,
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!)
      )
    }

    let rootJSON = StyleJSON(sources: layerSourcesJSON, layers: layerLayersJSON)

    do {
      let encoder = JSONEncoder()

      let data = try encoder.encode(rootJSON)
      let json = String(data: data, encoding: .utf8)!

      return json
    } catch {
      return nil
    }
  }
}

enum LayerTypeJSON: String, Codable {
  case vector, raster
}

struct LayerSourceJSON: Codable {
  let type: LayerTypeJSON
  let tiles: [String]

  let minzoom: Int?
  let maxzoom: Int?
  let tileSize: Int?
}

struct LayerLayerJSON: Codable {
  let id: String
  let type: LayerTypeJSON
  let source: String

  let minzoom: Int?
  let maxzoom: Int?
}

struct StyleJSON: Codable {
  var version = 8
  let sources: [String: LayerSourceJSON]
  let layers: [LayerLayerJSON]
}
