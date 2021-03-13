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
  
  init?(_ string: String) {
    let coords = string
      .split(separator: ",")
      .map({Double($0.trimmingCharacters(in: .whitespacesAndNewlines))})
      .filter({$0 != nil})
      as! [Double]

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
}
