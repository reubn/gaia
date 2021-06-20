import Foundation
import Mapbox

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

var interfacedLayersCache: [Int: Style.InterfacedLayer] = [:]
var interfacedSourcesCache: [Int: Style.InterfacedSource] = [:]

struct Style: Codable, Equatable, Hashable {
  var version = 8
  
  var sources: [String: Source]
  var layers: [Layer]
  
  var sprite: Sprite? = nil
  var glyphs: Glyphs? = nil
  var terrain: Terrain? = nil
  
  var interfacedLayers: [InterfacedLayer] {
    layers.compactMap({layer in
      let hashValue = layer.hashValue
      
      if let cached = interfacedLayersCache[hashValue] {
        return cached
      }
      
      guard let type = layer.type?.value as? String,
            let id = layer.id?.value as? String else {
        return nil
      }
      
      print("InterfacedLayer", id)
      
      var hex: String?
      var rawOpacity: NSNumber?
      var capabilities: Set<InterfacedLayer.Capability>
      
      switch type {
        case "line":
          hex = layer.paint?[dynamicMember: "line-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "line-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "circle":
          hex = layer.paint?[dynamicMember: "circle-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "circle-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "fill":
          hex = layer.paint?[dynamicMember: "fill-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "fill-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "raster":
          rawOpacity = layer.paint?[dynamicMember: "raster-opacity"]?.value as? NSNumber
          capabilities = [.opacity]
        default: capabilities = []
      }
      
      let opacity = rawOpacity?.doubleValue
      let colour = hex != nil ? UIColor(hex: hex!)?.withAlphaComponent(CGFloat(opacity ?? 1)) : nil
      
      let interfacedLayer = InterfacedLayer(id: id, capabilities: capabilities, colour: colour, opacity: opacity)
      interfacedLayersCache[hashValue] = interfacedLayer
      
      return interfacedLayersCache[hashValue]
    })
  }
  
  func with(_ layerOptions: [InterfacedLayer]) -> Self {
    var copy = self
    
    for desc in layerOptions {
      if let index = copy.layers.firstIndex(where: {$0.id?.value as? String == desc.id}),
         let type = copy.layers[index].type?.value as? String {
        let hashValue = copy.layers[index].hashValue
        interfacedLayersCache.removeValue(forKey: hashValue)
        
        copy.layers[index].paint = copy.layers[index].paint ?? AnyCodable([:])
        
        if let colour = desc.colour,
           let hex = colour.toHex() {
          let colourString = AnyCodable("#" + hex)
          switch type {
            case "line": copy.layers[index].paint?[dynamicMember: "line-color"] = colourString
            case "circle": copy.layers[index].paint?[dynamicMember: "circle-color"] = colourString
            case "fill": copy.layers[index].paint?[dynamicMember: "fill-color"] = colourString
            default: ()
          }
        }
        
        if let opacity = desc.opacity ?? {let o = desc.colour?.components?.alpha; return o != nil ? Double(o!) : nil}() {
          switch type {
            case "raster": copy.layers[index].paint?[dynamicMember: "raster-opacity"] = AnyCodable(opacity)
            case "line": copy.layers[index].paint?[dynamicMember: "line-opacity"] = AnyCodable(opacity)
            case "circle": copy.layers[index].paint?[dynamicMember: "circle-opacity"] = AnyCodable(opacity)
            case "fill": copy.layers[index].paint?[dynamicMember: "fill-opacity"] = AnyCodable(opacity)
            default: ()
          }
        }
 
      }
    }
    
    return copy
  }
  
  var interfacedSources: [InterfacedSource] {
    sources.enumerated().compactMap({element in
      let source = element.element.value
      let id = element.element.key
      
      let hashValue = source.hashValue(combining: id)
      
      if let cached = interfacedSourcesCache[hashValue] {
        return cached
      }
      
      print("InterfacedSource", id)
      
      guard let type = source.type?.value as? String else {
        return nil
      }

      var minZoom: NSNumber?
      var maxZoom: NSNumber?
      var bounds: MGLCoordinateBounds?
      var capabilities: Set<InterfacedSource.Capability>
      
      switch type {
        case "vector", "raster", "raster-dem":
          minZoom = source.minzoom?.value as? NSNumber
          maxZoom = source.maxzoom?.value as? NSNumber

          if let _bounds = (source.bounds?.value as? [NSNumber]) as? [CLLocationDegrees],
             _bounds.count == 4 {
            let sw = CLLocationCoordinate2D(latitude: _bounds[1], longitude: _bounds[0])
            let ne = CLLocationCoordinate2D(latitude: _bounds[3], longitude: _bounds[2])
            
            bounds = MGLCoordinateBounds(sw: sw, ne: ne)
          } else {
            bounds = nil
          }
          
          capabilities = [.minZoom, .maxZoom, .bounds]
        case "geojson":
          maxZoom = source.maxzoom?.value as? NSNumber
          
          if let data = source.data {
            bounds = geoJSON(bounds: data)
          }
          
          capabilities = [.maxZoom, .bounds]
        default: capabilities = []
      }
    
      
      let interfacedSource = InterfacedSource(
        id: id,
        capabilities: capabilities,
        minZoom: minZoom?.doubleValue,
        maxZoom: maxZoom?.doubleValue,
        bounds: bounds
      )
      interfacedSourcesCache[hashValue] = interfacedSource
      
      return interfacedSource
    })
  }
  
  func with(_ sourceOptions: [InterfacedSource]) -> Self {
    var copy = self
    
    for desc in sourceOptions {
      let id = desc.id
      if let source = copy.sources[id],
         let type = source.type?.value as? String {
        let hashValue = source.hashValue(combining: id)
        interfacedSourcesCache.removeValue(forKey: hashValue)

        if let minZoom = desc.minZoom {
          switch type {
            case "vector", "raster", "raster-dem": copy.sources[id]?.minzoom = AnyCodable(minZoom)
            default: ()
          }
        }
        
        if let maxZoom = desc.maxZoom {
          switch type {
            case "vector", "raster", "raster-dem", "geojson": copy.sources[id]?.maxzoom = AnyCodable(maxZoom)
            default: ()
          }
        }
        
        if let bounds = desc.bounds {
          switch type {
            case "vector", "raster", "raster-dem": copy.sources[id]?.bounds = bounds.jsonArray
            default: ()
          }
        }
        
      }
    }
    
    return copy
  }
  
  var zoomLevelsCovered: (min: Double, max: Double) {
    print("zoomLevels")
    return (
      min: interfacedSources.compactMap({$0.minZoom}).max() ?? 0,
      max: interfacedSources.compactMap({$0.maxZoom}).min() ?? 22
    )
  }
  
  var bounds: BoundsInfo {
    print("bounds")
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
}


extension Style {
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  typealias Sprite = String
  typealias Glyphs = String
  typealias Terrain = AnyCodable
  
  struct BoundsInfo {
    let individual: [MGLCoordinateBounds]
    let superbound: MGLCoordinateBounds?
  }
  
  struct InterfacedLayer {
    let id: String
    
    let capabilities: Set<Capability>
    
    var colour: UIColor?
    var opacity: Double?
    
    func setting(_ capability: Capability, to: Any?) -> Self{
      var copy = self
      
      if capabilities.contains(capability) {
        switch capability {
          case .colour: copy.colour = to as! UIColor?
          case .opacity: copy.opacity = to as! Double?
        }
      }
      
      return copy
    }
    
    enum Capability {
      case colour
      case opacity
    }
  }
  
  struct InterfacedSource {
    let id: String
    
    let capabilities: Set<Capability>
    
    var minZoom: Double?
    var maxZoom: Double?
    var bounds: MGLCoordinateBounds?
    
    func setting(_ capability: Capability, to: Any?) -> Self{
      var copy = self
      
      if capabilities.contains(capability) {
        switch capability {
          case .minZoom: copy.minZoom = to as! Double?
          case .maxZoom: copy.maxZoom = to as! Double?
          case .bounds: copy.bounds = to as! MGLCoordinateBounds?
        }
      }
      
      return copy
    }
    
    enum Capability {
      case minZoom
      case maxZoom
      case bounds
    }
  }
}
