import Foundation
import Turf
import Mapbox

struct LocationInfoFeature: Hashable {
  let title: String
  var subtitle: String? = nil
  
  let position: LocationInfoPosition
  
  init?(feature mGlFeature: MGLFeature, geoJSONDictionary: [String: Feature]){
    guard let id = mGlFeature.identifier as? String, let feature = geoJSONDictionary[id] else {
      return nil
    }
    
    self.title = feature.properties?["title"]??.rawValue as? String ?? "Unnamed Feature"
    self.subtitle = feature.properties?["title"]??.rawValue as? String
    
    print(feature)
    
    switch feature.geometry {
      case .point(let geometry): self.position = .coordinate(geometry.coordinates)
      case .lineString(let geometry): self.position = .multiPoint(geometry.coordinates)
      default: return nil
    }
  }
}
