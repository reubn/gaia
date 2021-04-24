import Foundation
import CoreLocation

struct CoordinatePair {
  var a: CLLocationCoordinate2D? = nil
  var b: CLLocationCoordinate2D? = nil
  
  var full: Bool {
    get {a != nil && b != nil}
  }
}
