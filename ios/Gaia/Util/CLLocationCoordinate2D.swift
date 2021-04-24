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
  
  private func format(gridReference accuracy: FormatAccuracy) -> String {
    // https://gist.github.com/ChrisLawther/45981e89581aa4eaca560c3c9b70ee08
    let lat1 = latitude.toRadians
    let lon1 = longitude.toRadians

    let (a1, b1) = (6378137.000, 6356752.3141)

    var e2 = 1 - (b1 * b1) / (a1 * a1)
    let nu1 = a1 / sqrt(1 - e2 * pow(sin(lat1),2))

    // First convert to cartesian from spherical polar coordinates
    var H = 0.0 // Third spherical coord
    let x1 = (nu1 + H) * cos(lat1) * cos(lon1)
    let y1 = (nu1 + H) * cos(lat1) * sin(lon1)
    let z1 = ((1 - e2) * nu1 + H) * sin(lat1)

    // Perform Helmut transform (to go between GRS80 (_1) and Airy 1830 (_2))
    let s = 20.4894E-6      // The scale factor -1

    // The translations along x,y,z axes respectively
    let (tx, ty, tz) = (-446.448, 125.157, -542.060)

    // The rotations along x,y,z respectively, in seconds
    let (rxs, rys, rzs) = (-0.1502, -0.2470, -0.8421)

    // ... in radians
    let (rx, ry, rz) = (rxs * .pi / (180 * 3600.0), rys * .pi / (180 * 3600.0), rzs * .pi / (180 * 3600.0))

    let x2 = tx + (1 + s) * x1 + (-rz) * y1 + (ry) * z1
    let y2 = ty + (rz) * x1 + (1 + s) * y1 + (-rx) * z1
    let z2 = tz + (-ry) * x1 + (rx) * y1 + (1 + s) * z1

    // Back to spherical polar coordinates from cartesian
    // Need some of the characteristics of the new ellipsoid
    // The GSR80 semi-major and semi-minor axes used for WGS84(m)
    let (a, b) = (6377563.396, 6356256.909)

    e2 = 1 - (b * b) / (a * a)              // The eccentricity of the Airy 1830 ellipsoid
    let p = sqrt(x2 * x2 + y2 * y2)

    // Lat is obtained by an iterative proceedure:
    var lat = atan2(z2, (p * (1 - e2)))     // Initial value
    var latold: Double = 2 * .pi

    var nu = 0.0
    while abs(lat - latold) > 1e-16 {
        (lat, latold) = (latold, lat)
        nu = a / sqrt(1 - e2 * pow(sin(latold),2))
        lat = atan2(z2 + e2 * nu * sin(latold), p)
    }

    // Lon and height are then pretty easy
    let lon = atan2(y2, x2)
    H = p / cos(lat) - nu

    // E, N are the British national grid coordinates - eastings and northings
    let F0 = 0.9996012717                   // scale factor on the central meridian
    let lat0 = 49 * .pi / 180.0            // Latitude of true origin (radians)
    let lon0 = -2 * .pi / 180.0            // Longtitude of true origin and central meridian (radians)
    let (N0, E0) = (-100000.0, 400000.0)    // Northing & easting of true origin (m)
    let n1 = (a - b) / (a + b)

    // meridional radius of curvature
    let rho = a * F0 * (1 - e2) * pow((1 - e2 * pow(sin(lat),2)),-1.5)
    let eta2 = nu * F0 / rho - 1

    let M1 = (1 + n1 + (5.0 / 4.0) * pow(n1,2) + (5.0 / 4.0) * pow(n1,3)) * (lat-lat0)
    let M2 = (3.0 * n1 + 3.0 * pow(n1,2) + (21.0 / 8.0) * pow(n1,3)) * sin(lat - lat0) * cos(lat + lat0)
    let M3 = ((15.0 / 8.0) * pow(n1,2) + (15.0 / 8.0) * pow(n1,3)) * sin(2.0 * (lat-lat0)) * cos(2.0 * (lat+lat0))
    let M4 = (35.0 / 24.0) * pow(n1,3) * sin(3.0 * (lat-lat0)) * cos(3.0 * (lat+lat0))

    // meridional arc
    let M = b * F0 * (M1 - M2 + M3 - M4)

    let I = M + N0
    let II = nu * F0 * sin(lat) * cos(lat) / 2.0
    let III = nu * F0 * sin(lat) * pow(cos(lat),3) * (5 - pow(tan(lat),2) + 9 * eta2) / 24.0
    let IIIA = nu * F0 * sin(lat) * pow(cos(lat),5) * (61 - 58 * pow(tan(lat),2) + pow(tan(lat),4)) / 720.0
    let IV = nu * F0 * cos(lat)
    let V = nu * F0 * pow(cos(lat),3) * (nu / rho - pow(tan(lat),2)) / 6.0
    let VI = nu * F0 * pow(cos(lat),5) * (5 - 18 * pow(tan(lat),2) + pow(tan(lat),4) + 14 * eta2 - 58 * eta2 * pow(tan(lat),2)) / 120.0

    let N = I + II * pow((lon - lon0), 2) + III * pow(lon - lon0, 4) + IIIA * pow(lon - lon0, 6)
    let E = E0 + IV * (lon - lon0) + V * pow(lon - lon0,3) + VI * pow(lon - lon0, 5)

    let x = Int(floor(E / 100000))
    let y = Int(floor(N / 100000))
    
    let e = String(Int(E.truncatingRemainder(dividingBy: 100000)))
    let n = String(Int(N.truncatingRemainder(dividingBy: 100000)))
    
    let lookup = [
      ["SV", "SQ", "SL", "SF", "SA", "NV", "NQ", "NL", "NF", "NA", "HV", "HQ", "HL"],
      ["SW", "SR", "SM", "SG", "SB", "NW", "NR", "NM", "NG", "NB", "HW", "HR", "HM"],
      ["SX", "SS", "SN", "SH", "SC", "NX", "NS", "NN", "NH", "NC", "HX", "HS", "HN"],
      ["SY", "ST", "SO", "SJ", "SD", "NY", "NT", "NO", "NJ", "ND", "HY", "HT", "HO"],
      ["SZ", "SU", "SP", "SK", "SE", "NZ", "NU", "NP", "NK", "NE", "HZ", "HU", "HP"],
      ["TV", "TQ", "TL", "TF", "TA", "OV", "OQ", "OL", "OF", "OA", "JV", "JQ", "JL"],
      ["TW", "TR", "TM", "TG", "TB", "OW", "OR", "OM", "OG", "OB", "JW", "JR", "JM"]
    ]
    
    let seemsValid = x >= 0 && y >= 0 && x < lookup.count && y < lookup[x].count
    
    if(!seemsValid){
      switch accuracy {
        case .high: return "XX 00000 00000"
        case .low: return "XX000000"
        case .specific(_): return "XX 0000 0000"
      }
    }
    
    let letters = lookup[x][y]
    
    switch accuracy {
      case .high: return "\(letters) \(e.prefix(5)) \(n.prefix(5))"
      case .low: return "\(letters)\(e.prefix(3))\(n.prefix(3))"
      case .specific(let places): return "\(letters) \(e.prefix(places)) \(n.prefix(places))"
    }
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
      return nil
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
