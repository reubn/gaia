import Foundation
import Mapbox
import ZippyJSON

class MarkerManager {
  static let shared = MarkerManager()
  
  let gaiaMarkerId = "gaiaMarker"
  
  var markerLayer: Layer? {
    LayerManager.shared.layers.first(where: {$0.markerLayer})
  }

  var markers: [Marker] {
    get {
      self.markerLayer?.style.interfacedSources
        .flatMap(extractMarkers)
      ?? []
    }
    
    set {
      guard let markerLayer = markerLayer ?? addMarkerLayer() else {
        return
      }
      
      let newSource = Style.Source([
        "type": "geojson",
        "data": [
          "type": "FeatureCollection",
          "features": newValue.map({$0.geoJSON})
        ]
      ])
      
      let newInterfacedSource = Style.InterfacedSource.create((gaiaMarkerId, newSource))!
      
      markerLayer.style = markerLayer.style.with([newInterfacedSource])
  
      LayerManager.shared.save()
    }
  }
  
  lazy var latestColour: UIColor = markers.last?.colour ?? .systemPink
  
  func extractMarkers(_ interfacedSource: Style.InterfacedSource) -> [Marker] {
    if let geoJSONData = interfacedSource.geoJSONData {
      let features = geoJSON(flatten: geoJSONData)
      return features.compactMap({Marker(feature: $0)})
    }
    
    return []
  }
  
  func markers(in bounds: MGLCoordinateBounds) -> [Marker] {
    markers.filter({bounds.contains(coordinate: $0.coordinate)})
  }
  
  func addMarkerLayer() -> Layer? {
    print("addMarkerLayer")
    let metadata = LayerDefinition.Metadata(id: gaiaMarkerId, name: "Gaia Markers", group: "overlay")
    let user = LayerDefinition.User(groupIndex: 0, pinned: false, enabled: true, quickToggle: false, markerLayer: true)
    
    let styleLayer = Style.Layer([
      "id": gaiaMarkerId,
      "paint": [
        "circle-color": [
          "get",
          "colour"
        ],
        "circle-opacity": 1,
        "circle-radius": [
          "interpolate",
          [
            "linear"
          ],
          [
            "zoom"
          ],
          5,
          3,
          10,
          5,
          16,
          6
        ]
      ],
      "source": gaiaMarkerId,
      "type": "circle"
    ])
    let style = Style(sources: [:], layers: [styleLayer])
    let layerDefinition = LayerDefinition(metadata: metadata, user: user, style: style)
    
    return LayerManager.shared.accept(layerDefinition: layerDefinition).layer
  }
}

struct Marker: Hashable, Equatable {
  let coordinate: CLLocationCoordinate2D
  let id: UUID
  
  let colour: UIColor
  
  var title: String? = nil
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.id == rhs.id
  }
}

extension Marker {
  init?(feature: AnyCodable?){
    guard
      let feature = feature,
      let properties = feature.properties,
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
    
    let title = properties.title?.value as? String
    
    let coordinate = CLLocationCoordinate2D(latitude: coordinateArray[1], longitude: coordinateArray[0])

    self.init(coordinate: coordinate, id: uuid, colour: colour, title: title)
  }
  
  init(coordinate: CLLocationCoordinate2D, colour: UIColor=MarkerManager.shared.latestColour, title: String?=nil){
    self.init(coordinate: coordinate, id: UUID(), colour: colour, title: title)
  }
  
  init(marker: Self, colour: UIColor=MarkerManager.shared.latestColour){
    self.init(coordinate: marker.coordinate, id: marker.id, colour: colour, title: marker.title)
  }
  
  init(marker: Self, colour: UIColor=MarkerManager.shared.latestColour, title: String?){
    self.init(coordinate: marker.coordinate, id: marker.id, colour: colour, title: title)
  }
  
  var geoJSON: AnyCodable {
    [
      "type": "Feature",
      "properties": [
        "gaiaUUID": id.uuidString,
        "colour": "#\(colour.toHex() ?? "000000")",
        "title": title
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
}
