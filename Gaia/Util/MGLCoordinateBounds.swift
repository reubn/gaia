import Foundation
import Mapbox

extension MGLCoordinateBounds: Equatable, Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    MGLCoordinateBoundsEqualToCoordinateBounds(lhs, rhs)
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
}
