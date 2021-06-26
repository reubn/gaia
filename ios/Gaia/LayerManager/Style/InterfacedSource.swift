import Foundation
import Mapbox

extension Style {
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
    
    static func create(_ tuple: (String, Source)) -> Self? {
      let (id, source) = tuple
      
      let hashValue = source.hashValue(combining: id)
      
      if let cached = interfacedSourcesCache[hashValue] {
        return cached
      }
      
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
    }
    
    enum Capability {
      case minZoom
      case maxZoom
      case bounds
    }
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
}
