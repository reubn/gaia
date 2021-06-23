import Foundation

extension Collection {
  var lastIndex: Index {
    get {
      self.index(self.endIndex, offsetBy: -1)
    }
  }
  
  func index(after: Index, wrap: Bool) -> Index {
    if(!wrap) {
      return self.index(after: after)
    }
    
    return self.index(after, offsetBy: 1, limitedBy: self.lastIndex) ?? self.startIndex
  }
  
  func index(before: Index, wrap: Bool) -> Index {
    if(!wrap) {
      return self.index(before, offsetBy: -1)
    }
    
    return self.index(before, offsetBy: -1, limitedBy: self.startIndex) ?? self.lastIndex
  }
  
  func firstMap<T>(_ transform: (Element) -> T?) -> T? {
    for element in self {
      if let cast = transform(element) {
        return cast
      }
    }
    
    return nil
  }
}
