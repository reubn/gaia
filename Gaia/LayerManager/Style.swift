import Foundation

class Style {
  let sortedLayers: [Layer]
  
  init(sortedLayers: [Layer]){
    self.sortedLayers = sortedLayers
  }
  
  var needsDarkUI: Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    if(topNonOverlay == nil) {return true}

    return topNonOverlay!.group == "aerial"
  }
  
  var url: URL? {
    do {
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFilename = ProcessInfo().globallyUniqueString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try jsonString!.data(using: .utf8)!.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  var jsonString: String? {
    jsonData != nil ? String(data: jsonData!, encoding: .utf8) : nil
  }
  
  var jsonData: Data? {
    do {
      let encoder = JSONEncoder()

      return try encoder.encode(jsonObject)
      
    } catch {
      return nil
    }
  }
  
  var jsonObject: StyleJSON {
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

    return StyleJSON(sources: layerSourcesJSON, layers: layerLayersJSON)
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
