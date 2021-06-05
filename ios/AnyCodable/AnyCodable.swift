// https://github.com/Flight-School/AnyCodable
// https://github.com/amichnia/AnyCodable

/**
 A type-erased `Codable` value.

 The `AnyCodable` type forwards encoding and decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode or decode mixed-type values in dictionaries
 and other collections that require `Encodable` or `Decodable` conformance
 by declaring their contained type to be `AnyCodable`.

 - SeeAlso: `AnyEncodable`
 - SeeAlso: `AnyDecodable`
 */

@dynamicMemberLookup @frozen public struct AnyCodable: Codable {
    public var value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable: _AnyEncodable, _AnyDecodable {}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyCodable(\(value.debugDescription))"
        default:
            return "AnyCodable(\(description))"
        }
    }
}

extension AnyCodable {
  subscript(dynamicMember member: String) -> AnyCodable? {
    get {
      switch self.value {
      case let anyCodable as AnyCodable:
        return anyCodable[dynamicMember: member]
      case let dictionary as [String: Any?] where dictionary[member] != nil:
        return AnyCodable(dictionary[member]!)
      default:
        return nil
      }
    }
    set {
      switch self.value {
      case var anyCodable as AnyCodable:
        anyCodable[dynamicMember: member] = newValue
        self.value = anyCodable
      case var dictionary as [String: Any?]:
        if let newValue = newValue {
          dictionary[member] = newValue.value
        } else {
          dictionary.removeValue(forKey: member)
        }
        self.value = dictionary
      default:
        break
      }
    }
  }
  
  subscript(dynamicMember member: Int) -> AnyCodable? {
    get {
      switch self.value {
      case let anyCodable as AnyCodable:
        return anyCodable[dynamicMember: member]
      case let array as [Any] where member >= 0 && member < array.count:
        return AnyCodable(array[member])
      default:
        return nil
      }
    }
    set {
      switch self.value {
      case var anyCodable as AnyCodable:
        anyCodable[dynamicMember: member] = newValue
        self.value = anyCodable
      case var array as [Any] where member >= 0 && member < array.count:
        array[member] = newValue as Any
        self.value = array
      default:
        break
      }
    }
  }
  
  subscript(index: Int) -> AnyCodable? {
    get {
      switch self.value {
      case let anyCodable as AnyCodable:
        return anyCodable[index]
      case let array as [Any]:
        return AnyCodable(array[index])
      default:
        return nil
      }
    }
    set {
      guard let newValue = newValue else {
        return // ??? not sure what to do here, like what means array[2] = nil
      }
      
      switch self.value {
      case var anyCodable as AnyCodable:
        anyCodable[index] = newValue
        self.value = anyCodable
      case var array as [Any] where index >= 0 && index < array.count:
        array[index] = newValue as Any
        self.value = array
      default:
        break
      }
    }
  }
}

public struct AnyCodableIterator: IteratorProtocol {
  private let anyCodable: AnyCodable
  private var index = 0

  init(_ anyCodable: AnyCodable) {
    self.anyCodable = anyCodable
  }

  mutating public func next() -> AnyCodable? {
    let value = anyCodable[dynamicMember: index]
    index += 1
    
    return value
  }
}

extension AnyCodable: Sequence {
  public typealias Element = AnyCodable
  
  public func makeIterator() -> AnyCodableIterator {
    AnyCodableIterator(self)
  }
}

extension AnyCodable: ExpressibleByNilLiteral {}
extension AnyCodable: ExpressibleByBooleanLiteral {}
extension AnyCodable: ExpressibleByIntegerLiteral {}
extension AnyCodable: ExpressibleByFloatLiteral {}
extension AnyCodable: ExpressibleByStringLiteral {}
extension AnyCodable: ExpressibleByArrayLiteral {}
extension AnyCodable: ExpressibleByDictionaryLiteral {}

extension AnyCodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyCodable]:
            hasher.combine(value)
        case let value as [AnyCodable]:
            hasher.combine(value)
        default:
            break
        }
    }
}
