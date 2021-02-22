import Foundation

import AnyCodable

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

struct Style: Codable, Equatable {
  var version = 8
  let sources: [String: AnyCodable]
  let layers: [AnyCodable]
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  func toURL() -> URL? {
    do {
      let encoder = JSONEncoder()
      
      let data = try encoder.encode(self)
      
      let temporaryFilename = UUID().uuidString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
}
