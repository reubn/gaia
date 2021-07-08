import Foundation
import CoreLocation

import ZippyJSON

extension URLInterface {
  enum Command {
    case go(CLLocationCoordinate2D)
    case `import`(URL)
    case download(PackContext)
    case clearCache
    
    case invalid
  }
  
  func toQueryItem(command: Command) -> URLQueryItem? {
    switch command {
      case .go(let coordinate):
        return go(coordinate)
      case .import(let url):
        return `import`(url)
      case .download(let context):
        return download(context)
      case .clearCache:
        return clearCache()
      case .invalid:
        return nil
    }
  }
  
  func toCommand(_ queryItem: URLQueryItem) -> Command {
    switch queryItem.name {
      case "go":
        return go(queryItem)
      case "import":
        return `import`(queryItem)
      case "download":
        return download(queryItem)
      case "clearCache":
        return clearCache(queryItem)
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
  
  func `import`(_ url: URL) -> URLQueryItem {
    URLQueryItem(name: "import", value: url.absoluteString)
  }
  
  func `import`(_ queryItem: URLQueryItem) -> Command {
    let url = URL(string: queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlAllowedCharacters) ?? "")

    if(url != nil) {
      return .import(url!)
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
    let decoder = ZippyJSONDecoder()
    
    let data = queryItem.value?.data(using: .utf8)!
    
    let context = data != nil
      ? try? decoder.decode(PackContext.self, from: data!)
      : nil

    return context != nil
      ? .download(context!)
      : .invalid
  }
  
  func clearCache() -> URLQueryItem {
    URLQueryItem(name: "clearCache", value: "")
  }

  func clearCache(_ queryItem: URLQueryItem) -> Command {
    return .clearCache
  }
}
