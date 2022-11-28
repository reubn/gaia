import Foundation
import CoreLocation

struct CoordinatePair {
  var a: CLLocationCoordinate2D? = nil
  var b: CLLocationCoordinate2D? = nil
  
  var full: Bool {
    get {a != nil && b != nil}
  }
}

struct CoordinateArrayWithCoordinate {
  var coordinateArray: [CLLocationCoordinate2D] = []
  var coordinate: CLLocationCoordinate2D? = nil
  
  var full: Bool {
    get {!coordinateArray.isEmpty && coordinate != nil}
  }
}

