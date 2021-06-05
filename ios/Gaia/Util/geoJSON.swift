import Foundation
import Mapbox

public func geoJSON(appearsToBe object: AnyCodable) -> Bool {
  if let type = object.type?.value as? String {
    return ["FeatureCollection", "Feature", "Point", "LineString", "MultiPoint", "Polygon", "MultiLineString", "MultiPolygon", "GeometryCollection"].contains(type)
  }
  
  return false
}

public func geoJSON(bounds root: AnyCodable) -> MGLCoordinateBounds? {
  let coords = geoJSON(flatten: root).flatMap(featureToCoords)

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

public func geoJSON(flatten object: AnyCodable) -> [AnyCodable?]{
  let type = object.type?.value as? String
  
  switch type {
    case "FeatureCollection": return object.features?.flatMap({geoJSON(flatten: $0)}) ?? []
    case "Feature": return [object]
    default: print("Unhandled Feature"); return []
  }
}

fileprivate func featureToCoords(_ optionalFeature: AnyCodable?) -> [GeoJSONCoord?]{
  guard let feature = optionalFeature,
        feature.type?.value as? String == "Feature",
        let geometry = feature.geometry,
        let geometryType = geometry.type?.value as? String,
        let coords = geometry.coordinates
  else {
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
}

typealias GeoJSONCoord = [CLLocationDegrees]

fileprivate func castCoord(_ coordinates: AnyCodable?) -> GeoJSONCoord? {
  return coordinates?.value as? [NSNumber] as? [CLLocationDegrees]
}
