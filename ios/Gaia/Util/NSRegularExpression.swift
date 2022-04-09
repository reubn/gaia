import Foundation

extension NSRegularExpression {
  func matches(_ string: String) -> [NSTextCheckingResult] {
    let range = NSRange(location: 0, length: string.utf16.count)
    
    return matches(in: string, range: range)
  }
  
  func replaceMatches(_ string: String, options: MatchingOptions=[], with: String) -> String {
    let mutableString = NSMutableString(string: string)
    let range = NSRange(location: 0, length: string.utf16.count)
    
    replaceMatches(in: mutableString, options: options, range: range, withTemplate: with)
    
    return String(mutableString)
  }
}
