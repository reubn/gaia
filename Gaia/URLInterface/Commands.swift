import Foundation
import CoreLocation

extension URLInterface {
  enum Command {
    case go(CLLocationCoordinate2D)
    case layer(URL)
    case download(PackContext)
    
    case invalid
  }
  
  func toQueryItem(command: Command) -> URLQueryItem? {
    switch command {
      case .go(let coordinate):
        return go(coordinate)
      case .layer(let url):
        return layer(url)
      case .download(let context):
        return download(context)
      case .invalid:
        return nil
    }
  }
  
  func toCommand(_ queryItem: URLQueryItem) -> Command {
    switch queryItem.name {
      case "go":
        return go(queryItem)
      case "layer":
        return layer(queryItem)
      case "download":
        return download(queryItem)
      default:
        return .invalid
    }
  }
  
  func go(_ coordinate: CLLocationCoordinate2D) -> URLQueryItem {
    URLQueryItem(name: "go", value: "\(coordinate.latitude),\(coordinate.longitude)")
  }

  func go(_ queryItem: URLQueryItem) -> Command {
    let coordinate = queryItem.value != nil ? CLLocationCoordinate2D(queryItem.value!) : nil
    
    return coordinate != nil
      ? .go(coordinate!)
      : .invalid
  }
  
  func layer(_ url: URL) -> URLQueryItem {
    URLQueryItem(name: "layer", value: url.absoluteString)
  }
  
  func layer(_ queryItem: URLQueryItem) -> Command {
    let url = URL(string: queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlAllowedCharacters) ?? "")

    if(url != nil) {
      return .layer(url!)
    }
    
    return .invalid
  }
  
  func download(_ context: PackContext) -> URLQueryItem {
    let encoder = JSONEncoder()
  
    let data = try? encoder.encode(context)
    let json = data != nil ? String.init(data: data!, encoding: .utf8) : nil
  
    return URLQueryItem(name: "download", value: json)
  }
  
  func download(_ queryItem: URLQueryItem) -> Command {
    let decoder = JSONDecoder()
    
    let data = queryItem.value?.data(using: .utf8)!
    
    let context = data != nil
      ? try? decoder.decode(PackContext.self, from: data!)
      : nil

    return context != nil
      ? .download(context!)
      : .invalid
  }
}
