import Foundation
import Mapbox

func getGeoJSONBounds(_ root: AnyCodable) -> MGLCoordinateBounds? {
  let coords = processFeature(root)

  var minLat: CLLocationDegrees?
  var minLon: CLLocationDegrees?
  
  var maxLat: CLLocationDegrees?
  var maxLon: CLLocationDegrees?
  
  for case let latLon? in coords {
    let lat = latLon[1]
    let lon = latLon[0]
    
    minLat = min(minLat ?? lat, lat)
    minLon = min(minLon ?? lon, lon)
    
    maxLat = max(maxLat ?? lat, lat)
    maxLon = max(maxLon ?? lon, lon)
  }
  
  if(minLat == nil){
    return nil
  }
  
  let sw = CLLocationCoordinate2D(latitude: minLat!, longitude: minLon!)
  let ne = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLon!)
  
  return MGLCoordinateBounds(sw: sw, ne: ne)
}

fileprivate func processFeature(_ feature: AnyCodable) -> [GeoJSONCoord?]{
  let type = feature.type?.value as? String
  
  switch type {
    case "FeatureCollection": return feature.features?.flatMap({processFeature($0)}) ?? []
    case "Feature":
      guard let geometry = feature.geometry,
            let geometryType = geometry.type?.value as? String,
            let coords = geometry.coordinates
      else {
        print("Error Parsing geoJSON")
        return []
      }

      switch geometryType {
        case "Point": return [castCoord(coords)]
        case "LineString", "MultiPoint": return coords.map({castCoord($0)})
        case "Polygon": return coords[0]?.map({castCoord($0)}) ?? []
        case "MultiLineString": return coords.flatMap({$0.map({castCoord($0)})})
        case "MultiPolygon": return coords.flatMap({$0[0]?.map({castCoord($0)}) ?? []})
        default: print("Unhandled Geometry"); return []
      }
    default: print("Unhandled Feature"); return []
  }
}

typealias GeoJSONCoord = [CLLocationDegrees]

fileprivate func castCoord(_ coordinates: AnyCodable?) -> GeoJSONCoord? {
  return coordinates?.value as? [NSNumber] as? [CLLocationDegrees]
}
