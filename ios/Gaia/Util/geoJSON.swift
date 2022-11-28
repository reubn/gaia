import Foundation
import Turf
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

extension Geometry {
  static func from(anyCodable: AnyCodable?) -> GeometryConvertible? {
    guard
      let type = anyCodable?.type?.value as? String,
      let coordinates = anyCodable?.coordinates
    else {return nil}
    
    switch type {
      case "Point":
        if let coordinates = CLLocationCoordinate2D(anyCodable: coordinates){
          return Point(coordinates)
        }

      case "LineString":
        let coordinates = coordinates.compactMap({CLLocationCoordinate2D(anyCodable: $0)})
        return LineString(coordinates)
        
      case "MultiPoint":
        let coordinates = coordinates.compactMap({CLLocationCoordinate2D(anyCodable: $0)})
        return MultiPoint(coordinates)
        
      case "Polygon":
        let coordinates = coordinates.map({ring in ring.compactMap({CLLocationCoordinate2D(anyCodable: $0)})})
        return Polygon(coordinates)
        
      case "MultiLineString":
        let coordinates = coordinates.map({lineString in lineString.compactMap({CLLocationCoordinate2D(anyCodable: $0)})})
        return MultiLineString(coordinates)
        
      case "MultiPolygon":
        let coordinates = coordinates.map({polygon in polygon.map({ring in ring.compactMap({CLLocationCoordinate2D(anyCodable: $0)})})})
        return MultiPolygon(coordinates)
      default: print("Unhandled Geometry"); return nil
    }
    return nil
  }
}

extension JSONValue {
  static func from(anyCodable: AnyCodable?) -> JSONValue? {
    switch anyCodable?.value {
      case let value as Bool: return .boolean(value)
      case let value as Int: return .number(Double(value))
      case let value as Int8: return .number(Double(value))
      case let value as Int16: return .number(Double(value))
      case let value as Int32: return .number(Double(value))
      case let value as Int64: return .number(Double(value))
      case let value as UInt: return .number(Double(value))
      case let value as UInt8: return .number(Double(value))
      case let value as UInt16: return .number(Double(value))
      case let value as UInt32: return .number(Double(value))
      case let value as UInt64: return .number(Double(value))
      case let value as Float: return .number(Double(value))
      case let value as Double: return .number(value)
      case let value as String: return .string(value)
      case let value as [String: AnyCodable]:
        if let jsonObject = JSONObject.from(anyCodable: AnyCodable(value)) {
          return .object(jsonObject)
        }
      case let value as [AnyCodable]: return .array(JSONArray(value.compactMap({JSONValue.from(anyCodable: $0)})))
      case let value as AnyCodable: return JSONValue.from(anyCodable: value)
      case let value as [String: Any]:
        if let jsonObject = JSONObject.from(anyCodable: AnyCodable(value.mapValues({AnyCodable($0)}))) {
          return .object(jsonObject)
        }
      case let value as [Any]:  return .array(JSONArray(value.compactMap({JSONValue.from(anyCodable: AnyCodable($0))})))
        
      default: return nil
    }
    
    return nil
  }
}

extension JSONObject {
  static func from(anyCodable: AnyCodable?) -> JSONObject? {
    if let anyCodable = anyCodable, let object = anyCodable.value as? [String: Any] {
      let dictionary = object.map({($0.key, JSONValue.from(anyCodable: AnyCodable($0.value)))})
      return JSONObject(uniqueKeysWithValues: dictionary)
    }
    
    return nil
  }
}

extension GeoJSONObjectConvertible {
  static func from(anyCodable: AnyCodable?) -> GeoJSONObjectConvertible? {
    guard
      let anyCodable = anyCodable,
      let type = anyCodable.type?.value as? String
    else {return nil}

    switch type {
      case "FeatureCollection":
        let features = anyCodable.features?.compactMap({GeoJSONObject.from(anyCodable: $0) as? Feature}) ?? []
        return FeatureCollection(features: features)

      case "Feature":
        let geometry = Geometry.from(anyCodable: anyCodable.geometry)
        var feature = Feature(geometry: geometry)

        feature.identifier = FeatureIdentifier(rawValue: anyCodable.id?.value as? String)
        feature.properties = JSONObject.from(anyCodable: anyCodable.properties)
        
        return feature

      default: return Geometry.from(anyCodable: anyCodable)
    }
  }
}

extension GeoJSONObjectConvertible {
  func flattenFeatures() -> [Feature] {
    switch self.geoJSONObject {
      case .geometry: return []
      case .feature(let feature): return [feature]
      case .featureCollection(let featureCollection): return featureCollection.features.flatMap({$0.flattenFeatures()})
    }
  }
}
