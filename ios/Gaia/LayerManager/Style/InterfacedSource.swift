import Foundation
import Mapbox

extension Style {
  struct InterfacedSource {
    let id: String
    let type: String
    
    let capabilities: Set<Capability>
    
    var minZoom: Double?
    var maxZoom: Double?
    var bounds: MGLCoordinateBounds?
    
    var geoJSONData: AnyCodable? = nil
    
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
      
      if let cached = InterfacedCache.shared.sources[hashValue] {
        return cached
      }
      
      guard let type = source.type?.value as? String else {
        return nil
      }
      
      var minZoom: NSNumber?
      var maxZoom: NSNumber?
      var bounds: MGLCoordinateBounds?
      var capabilities: Set<InterfacedSource.Capability>
      
      var geoJSONData: AnyCodable?
      
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
          geoJSONData = source.data
          maxZoom = source.maxzoom?.value as? NSNumber
          
          if let data = source.data {
            bounds = geoJSON(bounds: data)
          }
          
          capabilities = [.maxZoom, .bounds]
        default: capabilities = []
      }
      
      
      let interfacedSource = InterfacedSource(
        id: id,
        type: type,
        capabilities: capabilities,
        minZoom: minZoom?.doubleValue,
        maxZoom: maxZoom?.doubleValue,
        bounds: bounds,
        geoJSONData: geoJSONData
      )
      InterfacedCache.shared.sources[hashValue] = interfacedSource
      
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
      var source = copy.sources[id] ?? Source(["type": desc.type])
      
      if let type = source.type?.value as? String {
        let hashValue = source.hashValue(combining: id)
        InterfacedCache.shared.sources.removeValue(forKey: hashValue)
        
        if let minZoom = desc.minZoom {
          switch type {
            case "vector", "raster", "raster-dem": source.minzoom = AnyCodable(minZoom)
            default: ()
          }
        }
        
        if let maxZoom = desc.maxZoom {
          switch type {
            case "vector", "raster", "raster-dem", "geojson": source.maxzoom = AnyCodable(maxZoom)
            default: ()
          }
        }
        
        if let bounds = desc.bounds {
          switch type {
            case "vector", "raster", "raster-dem": source.bounds = bounds.jsonArray
            default: ()
          }
        }
        
        if let geoJSON = desc.geoJSONData {
          switch type {
            case "geojson": source.data = geoJSON
            default: ()
          }
        }

        
        copy.sources[id] = source
      }
    }
    
    return copy
  }
}
