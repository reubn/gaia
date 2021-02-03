import Foundation

import AnyCodable

struct StyleJSON: Codable {
  var version = 8
  let sources: [String: AnyCodable]
  let layers: [AnyCodable]
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
}
