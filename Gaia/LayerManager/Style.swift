import Foundation

import AnyCodable
import Mapbox

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

struct Style: Codable, Equatable {
  var version = 8
  let sources: [String: Source]
  let layers: [Layer]
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  var zoomLevelsCovered: (min: Double, max: Double) {
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
      min: mins.max() ?? 0,
      max: maxes.min() ?? 22
    )
  }
  
  var boundsCovered: [MGLCoordinateBounds] {
    var allBounds: [MGLCoordinateBounds] = []
    
    for (_, source) in sources {
      let bounds = source.bounds?.value as? [CLLocationDegrees]
      
      if(bounds != nil && bounds!.count == 4) {
        let sw = CLLocationCoordinate2D(latitude: bounds![1], longitude: bounds![0])
        let ne = CLLocationCoordinate2D(latitude: bounds![3], longitude: bounds![2])
        
        allBounds.append(MGLCoordinateBoundsMake(sw, ne))
      }
    }

    return allBounds
  }
  
  var url: URL? {
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
