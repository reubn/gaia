// https://gist.github.com/ChrisLawther/45981e89581aa4eaca560c3c9b70ee08

import Foundation
import CoreLocation

fileprivate let lookup = [
  ["SV", "SQ", "SL", "SF", "SA", "NV", "NQ", "NL", "NF", "NA", "HV", "HQ", "HL"],
  ["SW", "SR", "SM", "SG", "SB", "NW", "NR", "NM", "NG", "NB", "HW", "HR", "HM"],
  ["SX", "SS", "SN", "SH", "SC", "NX", "NS", "NN", "NH", "NC", "HX", "HS", "HN"],
  ["SY", "ST", "SO", "SJ", "SD", "NY", "NT", "NO", "NJ", "ND", "HY", "HT", "HO"],
  ["SZ", "SU", "SP", "SK", "SE", "NZ", "NU", "NP", "NK", "NE", "HZ", "HU", "HP"],
  ["TV", "TQ", "TL", "TF", "TA", "OV", "OQ", "OL", "OF", "OA", "JV", "JQ", "JL"],
  ["TW", "TR", "TM", "TG", "TB", "OW", "OR", "OM", "OG", "OB", "JW", "JR", "JM"]
]

extension CLLocationCoordinate2D {
  init?(gridReference: String) {
    print("gr")
    let string = gridReference.replacingOccurrences(of: "[\\n\\r\\t\\s-_]", with: "", options: .regularExpression).uppercased()
    
    let firstTwo = string.prefix(2)

    var x: Int?
    var y: Int?
    
    for (_x, array) in lookup.enumerated() {
      if(x != nil) {break}
      
      for (_y, prefix) in array.enumerated() {
        if(prefix == firstTwo){
          x = _x
          y = _y
          break
        }
      }
    }
    
    guard let x = x, let y = y else {
      return nil
    }
    
    let numericPart = string.suffix(string.count - 2)
    
    guard numericPart.count % 2 == 0 else {
      return nil
    }
    
    let digits = numericPart.count / 2
    
    guard let e = Double(String(x) + numericPart.prefix(digits)),
          let n = Double(String(y) + numericPart.suffix(digits)) else {
      return nil
    }
    
    let magnitude = pow(10, Double(5 - digits))
    
    let easting = e * magnitude
    let northing = n * magnitude
    print("gr success")
    self.init(easting: easting, northing: northing)
  }
  
  init(easting E: Double, northing N: Double) {
    // The Airy 180 semi-major and semi-minor axes used for OSGB36 (m)
    let (a, b) = (6377563.396, 6356256.909)
    
    let F0 = 0.9996012717        // scale factor on the central meridian
    let lat0 = 49.0 * .pi / 180   // Latitude of true origin (radians)
    let lon0 = -2.0 * .pi / 180   // Longitude of true origin and central meridian (radians)
    
    // Northing & easting of true origin (m)
    let (N0, E0) = (-100000.0, 400000.0)
    
    let e2 = 1 - (b * b) / (a * a)     // eccentricity squared
    let n = (a - b) / (a + b)
    
    // Initialise the iterative variables
    var lat = lat0
    var M = 0.0
    
    while N - N0 - M >= 0.00001 { // Accurate to 0.01mm
      lat = (N - N0 - M) / (a * F0) + lat
      let M1 = (1.0 + n + (5 / 4) * pow(n,2) + (5 / 4) * pow(n,3)) * (lat - lat0)
      let M2 = (3.0 * n + 3.0 * pow(n,2) + (21 / 8) * pow(n,3)) * sin(lat - lat0) * cos(lat + lat0)
      let M3 = ((15 / 8) * pow(n,2) + (15 / 8) * pow(n,3)) * sin(2 * (lat - lat0)) * cos(2 * (lat + lat0))
      let M4 = (35 / 24) * pow(n,3) * sin(3 * (lat - lat0)) * cos(3 * (lat + lat0))
      
      // meridional arc
      M = b * F0 * (M1 - M2 + M3 - M4)
    }
    
    // transverse radius of curvature
    let nu = a * F0 / sqrt(1 - e2 * pow(sin(lat),2))
    
    // meridional radius of curvature
    let rho = a * F0 * (1 - e2) * pow((1 - e2 * pow(sin(lat),2)),(-1.5))
    let eta2 = nu / rho - 1.0
    
    let secLat = 1.0 / cos(lat)
    let VII = tan(lat) / (2 * rho * nu)
    
    let VIII = tan(lat) / (24 * rho * pow(nu,3)) * (5 + 3 * pow(tan(lat),2) + eta2 - 9 * pow(tan(lat),2) * eta2)
    let IX = tan(lat) / (720 * rho * pow(nu,5)) * (61 + 90 * pow(tan(lat),2) + 45 * pow(tan(lat),4))
    let X = secLat / nu
    let XI = secLat / (6 * pow(nu,3)) * (nu / rho + 2 * pow(tan(lat),2))
    let XII = secLat / (120 * pow(nu,5)) * (5 + 28 * pow(tan(lat),2) + 24 * pow(tan(lat),4))
    let XIIA = secLat / (5040 * pow(nu,7)) * (61 + 662 * pow(tan(lat),2) + 1320 * pow(tan(lat),4) + 720 * pow(tan(lat),6))
    let dE = E-E0
    
    // These are on the wrong ellipsoid currently: Airy1830. (Denoted by _1)
    let lat_1 = lat - VII * pow(dE,2) + VIII * pow(dE,4) - IX * pow(dE,6)
    let lon_1 = lon0 + X * dE - XI * pow(dE,3) + XII * pow(dE,5) - XIIA * pow(dE,7)
    
    // Want to convert to the GRS80 ellipsoid.
    // First convert to cartesian from spherical polar coordinates
    var H = 0.0     // Third spherical coord.
    let x_1 = (nu / F0 + H) * cos(lat_1) * cos(lon_1)
    let y_1 = (nu / F0 + H) * cos(lat_1) * sin(lon_1)
    let z_1 = ((1 - e2) * nu / F0 + H) * sin(lat_1)
    
    // Perform Helmut transform (to go between Airy 1830 (_1) and GRS80 (_2))
    let s = -20.4894 * pow(10.0,-6)           // The scale factor -1
    let tx = 446.448                        // The translations along x,y,z axes respectively
    let ty = -125.157
    let tz = 542.060
    let rxs = 0.1502                        // The rotations along x,y,z respectively, in seconds
    let rys = 0.2470
    let rzs = 0.8421
    let rx = rxs * .pi / (180 * 3600.0)    // In radians
    let ry = rys * .pi / (180 * 3600.0)
    let rz = rzs * .pi / (180 * 3600.0)
    let x_2 = tx + (1 + s) * x_1 + (-rz) * y_1 + (ry) * z_1
    let y_2 = ty + (rz) * x_1 + (1 + s) * y_1 + (-rx) * z_1
    let z_2 = tz + (-ry) * x_1 + (rx) * y_1 + (1 + s) * z_1
    
    // Back to spherical polar coordinates from cartesian
    // Need some of the characteristics of the new ellipsoid
    let a_2 = 6378137.000                   // The GSR80 semi-major and semi-minor axes used for WGS84(m)
    let b_2 = 6356752.3141
    let e2_2 = 1 - (b_2 * b_2) / (a_2 * a_2) // The eccentricity of the GRS80 ellipsoid
    let p = sqrt(pow(x_2,2) + pow(y_2,2))
    
    // Lat is obtained by an iterative proceedure:
    lat = atan2(z_2,(p * (1 - e2_2)))       // Initial value
    var latold = 2.0 * .pi
    
    var nu_2 = 0.0
    
    while abs(lat - latold) > pow(10,-16) {
      let latTemp = lat
      lat = latold
      latold = latTemp
      nu_2 = a_2 / sqrt(1 - e2_2 * pow(sin(latold),2))
      lat = atan2(z_2 + e2_2 * nu_2 * sin(latold), p)
    }
    
    // Lon and height are then pretty easy
    var lon = atan2(y_2, x_2)
    H = p / cos(lat) - nu_2
    
    // Convert to degrees
    lat = lat * 180 / .pi
    lon = lon * 180 / .pi
    
    self.init(latitude: lat, longitude: lon)
  }
  
  func format(gridReference accuracy: FormatAccuracy, space: Bool=false) -> String {
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
    
    let seemsValid = x >= 0 && y >= 0 && x < lookup.count && y < lookup[x].count
    
    let delimiter = space ? " " : ""
    let letters = seemsValid ? lookup[x][y] : "XX"
    let numberOfDigits: Int = {
      switch accuracy {
        case .low: return 3
        case .high: return 5
        case .specific(let int): return int
      }
    }()
    
    let eString = seemsValid ? String(e.prefix(numberOfDigits)) : String(repeating: "0", count: numberOfDigits)
    let nString = seemsValid ? String(n.prefix(numberOfDigits)) : String(repeating: "0", count: numberOfDigits)
    
    return letters + delimiter + eString + delimiter + nString
  }
}
