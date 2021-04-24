import Foundation
import Mapbox

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
}
