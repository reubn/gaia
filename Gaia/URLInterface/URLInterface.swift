import Foundation
import CoreLocation

class URLInterface {
  func decode(url: URL) -> Command {
    
    let decoded = url.absoluteString.replacingOccurrences(of: "gaia://", with: "").split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)
    
    let command = decoded[0]
    let parameters = String(decoded[1])
    
    switch command {
      case "go":
        return go(parameters)
      default:
        return .invalid
    }

  }
  
  func go(_ parameters: String) -> Command {
    let coords = parameters.split(separator: ",").map({Double($0.trimmingCharacters(in: .whitespacesAndNewlines))}).filter({$0 != nil}) as! [Double]

    if(coords.count == 2) {
      let coordinate = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])

      return CLLocationCoordinate2DIsValid(coordinate) ? .coordinate(coordinate) : .invalid
    }
    
    return .invalid
  }
  
  static var shared = URLInterface()
  
  enum Command {
    case coordinate(CLLocationCoordinate2D)
    
    case invalid
  }
}
