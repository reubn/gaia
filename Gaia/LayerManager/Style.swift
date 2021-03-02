import Foundation

import AnyCodable

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

struct Style: Codable, Equatable {
  var version = 8
  let sources: [String: Source]
  let layers: [Layer]
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  func getVisibleZoomLevels() -> (min: Double?, max: Double?){
    var mins: [Double] = []
    var maxes: [Double] = []
    
    for (_, source) in sources {
      let minZoom = source.minzoom?.value
      let maxZoom = source.maxzoom?.value
      
      if(minZoom != nil) {
        mins.append(minZoom as? Double ?? Double(minZoom as! Int))
      }
      
      if(maxZoom != nil) {
        maxes.append(maxZoom as? Double ?? Double(maxZoom as! Int))
      }
    }

    return (
      min: mins.max(),
      max: maxes.min()
    )
  }
  
  
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
