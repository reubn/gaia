import Foundation
import CoreLocation

extension URLInterface {
  enum Command {
    case go(CLLocationCoordinate2D)
    
    case invalid
  }
  
  func toString(command: Command) -> String {
    switch command {
      case .go(let coordinate):
        return go(coordinate)
      case .invalid:
        return ""
    }
  }
  
  func toCommand(command: String, parameters: String) -> Command {
    switch command {
      case "go":
        return go(parameters)
      default:
        return .invalid
    }
  }
  
  func go(_ coordinate: CLLocationCoordinate2D) -> String {
    "go\(separator)\(coordinate.latitude),\(coordinate.longitude)"
  }

  func go(_ parameters: String) -> Command {
    let coords = parameters
      .split(separator: ",")
      .map({Double($0.trimmingCharacters(in: .whitespacesAndNewlines))})
      .filter({$0 != nil})
      as! [Double]

    if(coords.count == 2) {
      let coordinate = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])

      return CLLocationCoordinate2DIsValid(coordinate) ? .go(coordinate) : .invalid
    }
    
    return .invalid
  }
}
