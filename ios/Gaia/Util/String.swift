import Foundation

extension String: Error {}
extension String {
  subscript(_ range: NSRange) -> String {
    let start = self.index(self.startIndex, offsetBy: range.lowerBound)
    let end = self.index(self.startIndex, offsetBy: range.upperBound)
    let subString = self[start..<end]
    
    return String(subString)
  }
}
