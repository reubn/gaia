import Foundation
import Mapbox

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

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

  var zoomLevelsCovered: (min: Double, max: Double) {
    var mins: [Double] = []
    var maxes: [Double] = []
    
    for (_, source) in sources {
      if let minZoom = source.minzoom?.value,
         let double = (minZoom as? NSNumber)?.doubleValue {
        mins.append(double)
      }
      
      if let maxZoom = source.maxzoom?.value,
         let double = (maxZoom as? NSNumber)?.doubleValue {
        maxes.append(double)
      }
    }

    return (
      min: mins.max() ?? 0,
      max: maxes.min() ?? 22
    )
  }
  
  var bounds: BoundsInfo {
    var superbound: MGLCoordinateBounds?
    var allBounds: [MGLCoordinateBounds] = []
    
    for (id, source) in sources {
      let type = source.type?.value as? String
      
      switch type {
        case "geojson":
          print("calculating bounds for geojson source", id)
          if let data = source.data,
             let bounds = geoJSON(bounds: data){
            superbound = superbound?.extend(with: bounds) ?? bounds
            allBounds.append(bounds)
          }
        case "raster", "raster-dem", "vector":
          let bounds = (source.bounds?.value as? [NSNumber]) as? [CLLocationDegrees]
          
          if(bounds != nil && bounds!.count == 4) {
            let sw = CLLocationCoordinate2D(latitude: bounds![1], longitude: bounds![0])
            let ne = CLLocationCoordinate2D(latitude: bounds![3], longitude: bounds![2])
            
            let newBounds = MGLCoordinateBounds(sw: sw, ne: ne)
            
            superbound = superbound?.extend(with: newBounds) ?? newBounds
            allBounds.append(newBounds)
          } else {
            // if a raster, vector layer has no bounds, then assume its worldwide - therefore short circuit, discarding bounds
            return BoundsInfo(individual: [], superbound: nil)
          }
        default: ()
      }
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
  
  var interfacedLayers: [InterfacedLayer] {
    layers.compactMap({layer in
      guard let type = layer.type?.value as? String,
            let id = layer.id?.value as? String else {
        return nil
      }
      
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
      
      return InterfacedLayer(id: id, capabilities: capabilities, colour: colour, opacity: opacity)
    })
  }
  
  func with(_ layerOptions: [InterfacedLayer]) -> Self {
    var copy = self
    
    for desc in layerOptions {
      if let index = layers.firstIndex(where: {$0.id?.value as? String == desc.id}),
         let type = copy.layers[index].type?.value as? String {
        
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
