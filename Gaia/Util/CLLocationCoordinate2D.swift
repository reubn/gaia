import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
  enum FormatAccuracy {
    case high
    case low
  }
  
  func format(toAccuracy: FormatAccuracy = .low) -> String {
    let lat = Double(latitude)
    let lng = Double(longitude)
    
    return toAccuracy == .low
      ? String(format: "%.4f, %.4f", lat, lng) // 11m worst-case
      : String(format: "%.6f, %.6f", lat, lng) // 11cm worst-case
  }
  
  func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
    let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
    let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
    
    return from.distance(from: to)
  }
}
