import Foundation
import CoreLocation

extension URLInterface {
  enum Command {
    case go(CLLocationCoordinate2D)
    case layer(URL)
    
    case invalid
  }
  
  func toString(command: Command) -> String {
    switch command {
      case .go(let coordinate):
        return go(coordinate)
      case .layer(let url):
        return layer(url)
      case .invalid:
        return ""
    }
  }
  
  func toCommand(command: String, parameters: String) -> Command {
    switch command {
      case "go":
        return go(parameters)
      case "layer":
        return layer(parameters)
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
      var coordinate = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
      
      if(!CLLocationCoordinate2DIsValid(coordinate)) {
        coordinate = CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
      }

      return CLLocationCoordinate2DIsValid(coordinate) ? .go(coordinate) : .invalid
    }
    
    return .invalid
  }
  
  func layer(_ url: URL) -> String {
    "layer\(separator)\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
  }
  
  func layer(_ parameters: String) -> Command {
    let url = URL(string: parameters.trimmingCharacters(in: .whitespacesAndNewlines).removingPercentEncoding ?? "")

    if(url != nil) {
      return .layer(url!)
    }
    
    return .invalid
  }
}
