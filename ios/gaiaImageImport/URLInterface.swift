import Foundation

class URLInterface {
  let baseURL = URL(string: "gaia://")!
  
  func encode(commands: [Command]) -> URL? {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
    components.queryItems = commands.compactMap({toQueryItem(command: $0)})
    
    return components.url
  }
  
  static var shared = URLInterface()
}
