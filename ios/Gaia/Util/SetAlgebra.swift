import Foundation

extension SetAlgebra {
  mutating func set(_ element: Self.Element, to: Bool) {
    if(to) {
      self.insert(element)
    } else {
      self.remove(element)
    }
  }
}
