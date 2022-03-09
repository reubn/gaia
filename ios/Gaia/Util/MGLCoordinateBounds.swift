import Foundation
import Mapbox
@_spi(Experimental)import MapboxMaps

extension MGLCoordinateBounds: Codable, Equatable, Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    MGLCoordinateBoundsEqualToCoordinateBounds(lhs, rhs)
  }
  
  public static func sortingByAreaFunc(lhs: Self, rhs: Self) -> Bool {
    return lhs.area < rhs.area
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sw)
    hasher.combine(ne)
  }
  
  public var se: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: sw.latitude, longitude: ne.longitude)
  }
  
  public var nw: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: ne.latitude, longitude: sw.longitude)
  }
  
  public var span: MGLCoordinateSpan {
    MGLCoordinateBoundsGetCoordinateSpan(self)
  }
  
  public var area: CLLocationDegrees {
    span.latitudeDelta * span.longitudeDelta
  }
  
  public var center: CLLocationCoordinate2D {
    sw.midpoint(between: ne)
  }
  
  public func contains(coordinate: CLLocationCoordinate2D) -> Bool {
    MGLCoordinateInCoordinateBounds(coordinate, self)
  }
  
  public func intersects(with: Self) -> Bool {
    MGLCoordinateBoundsIntersectsCoordinateBounds(self, with)
  }
  
  public func extend(with: Self) -> Self {
    let minLat = min(sw.latitude, with.sw.latitude)
    let minLon = min(sw.longitude, with.sw.longitude)
    
    let maxLat = max(ne.latitude, with.ne.latitude)
    let maxLon = max(ne.longitude, with.ne.longitude)
    
    let swNew = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
    let neNew = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
    
    return Self(sw: swNew, ne: neNew)
  }
  
  enum CodingKeys: String, CodingKey {
    case sw
    case ne
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(sw, forKey: .sw)
    try container.encode(ne, forKey: .ne)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let sw = try container.decode(CLLocationCoordinate2D.self, forKey: .sw)
    let ne = try container.decode(CLLocationCoordinate2D.self, forKey: .ne)

    self.init(sw: sw, ne: ne)
  }
  
  public init(_ from: CoordinateBounds) {
    self.init(sw: from.southwest, ne: from.northeast)
  }
  
  public var jsonArray: AnyCodable {
    [sw.longitude, sw.latitude, ne.longitude, ne.latitude]
  }
  
  public func toCoordinateBounds() -> CoordinateBounds {
    return CoordinateBounds(self)
  }
}

extension CoordinateBounds {
  convenience init(_ from: MGLCoordinateBounds) {
    self.init(southwest: from.sw, northeast: from.ne)
  }
}
