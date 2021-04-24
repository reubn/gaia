import Foundation
import CoreLocation

extension CLLocationDegrees {
  init(radians: Double) {
    self.init(radians * 180 / .pi)
  }
  
  var toRadians: Self {self * .pi / 180}
}
