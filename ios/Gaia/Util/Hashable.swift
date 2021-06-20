import Foundation

extension Hashable {
  func hashValue<T: Hashable>(combining other: T) -> Int {
    var hasher = Hasher()
    hasher.combine(self)
    hasher.combine(other)
    
    return hasher.finalize()
  }
}
