import Foundation
import CoreLocation

extension URLInterface {
  enum Command {
    case go(CLLocationCoordinate2D)
    case invalid
  }
  
  func toQueryItem(command: Command) -> URLQueryItem? {
    switch command {
      case .go(let coordinate):
        return go(coordinate)
      case .invalid:
        return nil
    }
  }
  
  func go(_ coordinate: CLLocationCoordinate2D) -> URLQueryItem {
    URLQueryItem(name: "go", value: "\(coordinate.latitude),\(coordinate.longitude)")
  }
}
