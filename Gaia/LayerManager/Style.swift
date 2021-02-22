import Foundation

import AnyCodable

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

struct Style: Codable {
  var version = 8
  let sources: [String: AnyCodable]
  let layers: [AnyCodable]
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  func toURL() -> URL? {
    do {
      
      let encoder = JSONEncoder()
      
      let data = try encoder.encode(self)
      
      let hash = String(data.hashValue)
      
      let temporaryFilename = hash + ".style"
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
      
      if(FileManager.default.fileExists(atPath: temporaryFileURL.path)) {
        return temporaryFileURL
      }

      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
}
