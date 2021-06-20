import Foundation
import Mapbox

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

var interfacedLayersCache: [Int: Style.InterfacedLayer] = [:]
var interfacedSourcesCache: [Int: Style.InterfacedSource] = [:]

struct Style: Codable, Equatable, Hashable {
  var version = 8
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  var sources: [String: Source]
  var layers: [Layer]
  
  typealias Sprite = String
  typealias Glyphs = String
  typealias Terrain = AnyCodable
  
  var sprite: Sprite? = nil
  var glyphs: Glyphs? = nil
  var terrain: Terrain? = nil
  
  var interfacedLayers: [InterfacedLayer] {
    layers.compactMap(InterfacedLayer.create)
  }
  
  var interfacedSources: [InterfacedSource] {
    sources.compactMap(InterfacedSource.create)
  }

  var zoomLevelsCovered: (min: Double, max: Double) {
    (
      min: interfacedSources.compactMap({$0.minZoom}).max() ?? 0,
      max: interfacedSources.compactMap({$0.maxZoom}).min() ?? 22
    )
  }
  
  var bounds: BoundsInfo {
    var superbound: MGLCoordinateBounds?
    var allBounds: [MGLCoordinateBounds] = []
    
    for source in interfacedSources {
      guard let _bounds = source.bounds else {
        // if a source has no bounds, then assume its worldwide - therefore short circuit, discarding bounds
        return BoundsInfo(individual: [], superbound: nil)
      }
      
      superbound = superbound?.extend(with: _bounds) ?? _bounds
      allBounds.append(_bounds)
    }
    
    return BoundsInfo(individual: allBounds, superbound: superbound)
  }
  
  var url: URL? {
    do {
      let encoder = JSONEncoder()
      
      let data = try encoder.encode(self)
      
      let temporaryFilename = UUID().uuidString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
      
      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  var supportsOpacity: Bool {
    interfacedLayers.contains(where: {$0.capabilities.contains(.opacity)})
  }
  var opacity: Double {
    interfacedLayers.compactMap({$0.opacity}).max() ?? 1
  }
  
  var supportsColour: Bool {
    interfacedLayers.contains(where: {$0.capabilities.contains(.colour)})
  }
  
  var colour: UIColor? {
    interfacedLayers.first(where: {$0.colour != nil})?.colour
  }
  
  struct BoundsInfo {
    let individual: [MGLCoordinateBounds]
    let superbound: MGLCoordinateBounds?
  }
}
