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
  public static func ==(lhs: AnyCodable, rhs: AnyCodable) -> Bool {
    return lhs.hashValue == rhs.hashValue
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
      hasher.combine(toHashable(value))
    }
}

func toHashable(_ value: Any) -> AnyHashable? {
  switch value {
    case let value as AnyHashable:
      return value
    case let value as [AnyHashable]:
      return value
    case let value as [[AnyHashable]]:
      return value
    case let value as [String: AnyHashable]:
      return value
    case let value as [Any]:
      let anyCodable = value.map(tryCastAnyHashable)
      return anyCodable
    case let value as [String: Any]:
      let anyCodable = value.mapValues(tryCastAnyHashable)
      return anyCodable
    case is Void:
      return nil
    
    default:
      fatalError("Unknown Type")
  }
}

func tryCastAnyHashable(_ value: Any) -> AnyHashable {
  return value as? AnyHashable ?? toHashable(value)
}
