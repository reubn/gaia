import Foundation

class URLInterface {
  let identifier = "gaia://"
  let separator: Character = "?"

  func encode(command: Command) -> URL {
    let string = toString(command: command)
    
    return URL(string: "\(identifier)\(string)") ?? URL(string: identifier)!
  }
  
  func decode(url: URL) -> Command {
    let decoded = url.absoluteString
      .replacingOccurrences(of: identifier, with: "")
      .split(separator: separator, maxSplits: 1, omittingEmptySubsequences: true)
    
    let command = String(decoded[0])
    let parameters = String(decoded[1])
    
    return toCommand(command: command, parameters: parameters)
  }

  static var shared = URLInterface()
}
