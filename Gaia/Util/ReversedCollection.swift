import Foundation

extension ReversedCollection {
  var lastIndex: Index {
    get {
      self.index(before: self.endIndex)
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
      return self.index(before: before)
    }
    
    return self.index(before, offsetBy: -1, limitedBy: self.startIndex) ?? self.lastIndex
  }
}
