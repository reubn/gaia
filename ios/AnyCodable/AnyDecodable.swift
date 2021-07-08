// https://github.com/Flight-School/AnyCodable

#if canImport(Foundation)
import Foundation
#endif

/**
 A type-erased `Decodable` value.

 The `AnyDecodable` type forwards decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can decode mixed-type values in dictionaries
 and other collections that require `Decodable` conformance
 by declaring their contained type to be `AnyDecodable`:

     let json = """
     {
         "boolean": true,
         "integer": 42,
         "double": 3.141592653589793,
         "string": "string",
         "array": [1, 2, 3],
         "nested": {
             "a": "alpha",
             "b": "bravo",
             "c": "charlie"
         },
         "null": null
     }
     """.data(using: .utf8)!

     let decoder = ZippyJSONDecoder()
     let dictionary = try! decoder.decode([String: AnyDecodable].self, from: json)
 */
@frozen public struct AnyDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

@usableFromInline
protocol _AnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}

extension AnyDecodable: _AnyDecodable {}

extension _AnyDecodable {
    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
        
      if let string = try? container.decode(String.self) {
        self.init(string)
      } else if let int = try? container.decode(Int.self) {
        self.init(int)
      } else if let array = try? container.decode([AnyDecodable].self) {
        self.init(array.map { $0.value })
      } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
        self.init(dictionary.mapValues { $0.value })
      } else if let double = try? container.decode(Double.self) {
        self.init(double)
      } else if container.decodeNil() {
        self.init(Optional<Self>.none)
      } else if let bool = try? container.decode(Bool.self) {
          self.init(bool)
      } else if let uint = try? container.decode(UInt.self) {
          self.init(uint)
      } else {
          throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value cannot be decoded")
      }
    }
}

extension AnyDecodable: Equatable {
  public static func ==(lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}

extension AnyDecodable: CustomStringConvertible {
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

extension AnyDecodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyDecodable(\(value.debugDescription))"
        default:
            return "AnyDecodable(\(description))"
        }
    }
}

extension AnyDecodable: Hashable {
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
        case let value as [String: AnyDecodable]:
            hasher.combine(value)
        case let value as [AnyDecodable]:
            hasher.combine(value)
        case let value as AnyDecodable:
          hasher.combine(value)
        case let value as [String: Any]:
          let anyDecodable = value.mapValues({AnyDecodable($0)})
          hasher.combine(anyDecodable)
        case let value as [Any]:
          let anyDecodable = value.map({AnyDecodable($0)})
          hasher.combine(anyDecodable)
        default:
            break
        }
    }
}
