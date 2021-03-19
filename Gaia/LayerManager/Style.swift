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
  
  struct BoundInfo {
    let individual: [MGLCoordinateBounds]
    let superbound: MGLCoordinateBounds?
  }
  
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
  
  var bounds: BoundInfo {
    var allBounds: [MGLCoordinateBounds] = []
    
    var minLat: CLLocationDegrees?
    var minLon: CLLocationDegrees?
    
    var maxLat: CLLocationDegrees?
    var maxLon: CLLocationDegrees?
    
    for (_, source) in sources {
      let bounds = source.bounds?.value as? [CLLocationDegrees]
      
      if(bounds != nil && bounds!.count == 4) {
        let sw = CLLocationCoordinate2D(latitude: bounds![1], longitude: bounds![0])
        let ne = CLLocationCoordinate2D(latitude: bounds![3], longitude: bounds![2])
        
        minLat = min(minLat ?? bounds![1], bounds![1])
        minLon = min(minLon ?? bounds![0], bounds![0])
        
        maxLat = max(maxLat ?? bounds![3], bounds![3])
        maxLon = max(maxLon ?? bounds![2], bounds![2])
        
        allBounds.append(MGLCoordinateBoundsMake(sw, ne))
      }
    }
    
    var superbound: MGLCoordinateBounds?
    
    if(minLat != nil) {
      let sw = CLLocationCoordinate2D(latitude: minLat!, longitude: minLon!)
      let ne = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLon!)
      
      superbound = MGLCoordinateBoundsMake(sw, ne)
    }

    return BoundInfo(individual: allBounds, superbound: superbound)
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
