import Foundation

extension NSRegularExpression {
  func matches(_ string: String) -> [NSTextCheckingResult] {
    let range = NSRange(location: 0, length: string.utf16.count)
    
    return matches(in: string, range: range)
  }
}
