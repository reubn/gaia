import Foundation
import CoreLocation

import Mapbox

extension CLLocationCoordinate2D: Codable, Equatable, Hashable {
  enum Format {
    case decimal(FormatAccuracy)
    case sexagesimal(FormatAccuracy)
    
    case gridReference(FormatAccuracy)
  }
  
  enum FormatAccuracy {
    case low
    case high
    
    case specific(Int)
  }
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitude)
    hasher.combine(longitude)
  }
  
  func format(_ _format: Format) -> String {
    switch _format {
      case .decimal(let accuracy): return format(decimal: accuracy)
      case .sexagesimal(let accuracy): return format(sexagesimal: accuracy)
      case .gridReference(let accuracy): return format(gridReference: accuracy)
      }
  }
  
  private func format(decimal accuracy: FormatAccuracy) -> String {
    let lat = Double(latitude)
    let lng = Double(longitude)
    
    switch accuracy {
      case .high: return String(format: "%.6f, %.6f", lat, lng) // 11cm worst-case
      case .low: return String(format: "%.4f, %.4f", lat, lng) // 11m worst-case
      case .specific(let places): return String(format: "%.\(places)f, %.\(places)f", lat, lng)
    }
  }
  
  private func format(sexagesimal accuracy: FormatAccuracy) -> String {
    let formatter = MGLCoordinateFormatter()
    formatter.unitStyle = .short

    switch accuracy {
      case .high, .specific: formatter.allowsSeconds = true
      case .low: formatter.allowsMinutes = true
    }
    
    return formatter.string(from: self).replacingOccurrences(of: ", ", with: " ")
  }
  
  func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
    let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
    let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
    
    return from.distance(from: to)
  }
  
  func bearing(to: CLLocationCoordinate2D) -> CLLocationDegrees {
    let lat1 = self.latitude.toRadians
    let lon1 = self.longitude.toRadians

    let lat2 = to.latitude.toRadians
    let lon2 = to.longitude.toRadians

    let dLon = lon2 - lon1
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    
    let θ = atan2(y, x)

    return CLLocationDegrees(radians: θ) + 180
  }
  
  func midpoint(between: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let lat1 = self.latitude.toRadians
    let lon1 = self.longitude.toRadians

    let lat2 = between.latitude.toRadians
    let lon2 = between.longitude.toRadians

    let dLon = lon2 - lon1
    let y = cos(lat2) * sin(dLon)
    let x = cos(lat2) * cos(dLon)

    let lat3 = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y))
    let lon3 = lon1 + atan2(y, cos(lat1) + x)

    return CLLocationCoordinate2D(
      latitude: CLLocationDegrees(radians: lat3),
      longitude: CLLocationDegrees(radians: lon3)
    )
  }
  
  init?(_ string: String) {
    let coords = string
      .split(separator: ",")
      .compactMap({Double($0.trimmingCharacters(in: .whitespacesAndNewlines))})

    if(coords.count == 2) {
      self.init()
      
      self.latitude = coords[0]
      self.longitude = coords[1]
      
      if(!CLLocationCoordinate2DIsValid(self)) {
        self.latitude = coords[1]
        self.longitude = coords[0]
      }

      if(!CLLocationCoordinate2DIsValid(self)){
        return nil
      }
    } else {
      self.init(gridReference: string)
      
      if(!CLLocationCoordinate2DIsValid(self)){
        return nil
      }
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(latitude)
    try container.encode(longitude)
  }
  
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let latitude = try container.decode(CLLocationDegrees.self)
    let longitude = try container.decode(CLLocationDegrees.self)

    self.init(latitude: latitude, longitude: longitude)
  }
}
