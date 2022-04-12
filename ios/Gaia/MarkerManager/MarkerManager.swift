import Foundation
import Mapbox
import ZippyJSON

class MarkerManager {
  static let shared = MarkerManager()
  
  var markerLayer: Layer? {
    LayerManager.shared.layers.first(where: {$0.markerLayer})
  }

  var markers: [Marker] {
    get {
      self.markerLayer?.style.interfacedSources
        .flatMap({$0.getMarkerGeoJSONFeatures()})
        .compactMap({Marker(feature: $0)})
      ?? []
    }
    
    set {
      guard let markerLayer = markerLayer else {
        return
      }
      
      let newSource = Style.Source([
        "type": "geojson",
        "data": [
          "type": "FeatureCollection",
          "features": newValue.map({$0.geoJSON})
        ]
      ])
      
      let gaiaMarkerSourceId = "gaiaMarkerSource"
      let newInterfacedSource = Style.InterfacedSource.create((gaiaMarkerSourceId, newSource))!
      
      markerLayer.style = markerLayer.style.with([newInterfacedSource])
  
      LayerManager.shared.save()
    }
  }
  
  lazy var latestColour: UIColor? = markers.last?.colour
  
  func markers(in bounds: MGLCoordinateBounds) -> [Marker] {
    markers.filter({bounds.contains(coordinate: $0.coordinate)})
  }
}

struct Marker: Equatable {
  let coordinate: CLLocationCoordinate2D
  let id: UUID
  
  var colour: UIColor
}

extension Marker {
  init?(feature: AnyCodable){
    guard let properties = feature.properties,
      let uuidString = properties.gaiaUUID?.value as? String,
      let uuid = UUID.init(uuidString: uuidString),
      let geometry = feature.geometry,
      let coordinateArray = geometry.coordinates?.value as? [Double] else {
        return nil
    }
    
    let colour: UIColor
    if
      let colourString = properties.colour?.value as? String,
      let _colour = UIColor(css: colourString) {
      colour = _colour
    } else {
      colour = .black
    }
    
    let coordinate = CLLocationCoordinate2D(latitude: coordinateArray[1], longitude: coordinateArray[0])

    self.init(coordinate: coordinate, id: uuid, colour: colour)
  }
  
  init(coordinate: CLLocationCoordinate2D, colour: UIColor){
    self.init(coordinate: coordinate, id: UUID(), colour: colour)
  }
  
  var geoJSON: AnyCodable {
    [
      "type": "Feature",
      "properties": [
        "gaiaMarker": true,
        "gaiaUUID": id.uuidString,
        "colour": "#\(colour.toHex() ?? "000000")"
      ],
      "geometry": [
        "coordinates": [
          coordinate.longitude,
          coordinate.latitude
        ],
        "type": "Point"
      ]
    ]
  }
  
  static func featureIsMarker(_ feature: AnyCodable?) -> Bool {
    feature?.properties?.gaiaMarker?.value as? Bool ?? false
  }
}
