import Foundation
import UIKit

import CoreGPX

struct LayerDefinition: Codable, Hashable {
  let metadata: Metadata
  var user: User? = User()
  
  let style: Style
  
  struct Metadata: Codable, Hashable {
    let id: String
    let name: String
    let group: String
    var overrideUIMode: String? = nil
    
    var attribution: String? = nil
  }
  
  struct User: Codable, Hashable {
    var groupIndex: Int = 0
    
    var pinned = false
    var enabled = true
    var quickToggle = false
    var markerLayer = false
  }
}

extension LayerDefinition.Metadata {
  init(layer: Layer){
    self.init(
      id: layer.id,
      name: layer.name,
      group: layer.group,
      overrideUIMode: layer.overrideUIMode,
      attribution: layer.attribution
    )
  }
  
  static func random(idPrefix: String?, namePrefix: String?, group: String="") -> Self {
    let random = randomString(length: 3)
    let id = (idPrefix != nil ? (idPrefix! + "_") : "") + random
    
    return Self(
      id: id,
      name: (namePrefix != nil ? (namePrefix! + " ") : "") + random,
      group: group
    )
  }
}

extension LayerDefinition.User {
  init(layer: Layer){
    self.init(
      groupIndex: Int(layer.groupIndex),
      
      pinned: layer.pinned,
      enabled: layer.enabled,
      quickToggle: layer.quickToggle,
      markerLayer: layer.markerLayer
    )
  }
}

extension LayerDefinition {
  init(layer: Layer){
    self.init(
      metadata: Metadata(layer: layer),
      user: User(layer: layer),
      style: layer.style
    )
  }
  
  init(style: Style, metadata _metadata: LayerDefinition.Metadata? = nil){
    let metadata = _metadata ?? .random(idPrefix: "style", namePrefix: "Style")
    
    self.init(
      metadata: metadata,
      style: style
    )
  }
  
  init(xyzURL: String, metadata _metadata: LayerDefinition.Metadata? = nil){
    let metadata = _metadata ?? .random(idPrefix: "xyz", namePrefix: "XYZ")
  
    self.init(
      metadata: metadata,
      style: Style(
        sources: [
          metadata.id: [
            "type": "raster",
            "tiles": [xyzURL]
          ]
        ],
        layers: [
          [
            "id": metadata.id,
            "source": metadata.id,
            "type": "raster"
          ]
        ]
      )
    )
  }
  
  init(gpx: GPXRoot, metadata _metadata: LayerDefinition.Metadata? = nil){
    let metadata = _metadata ?? .random(idPrefix: "gpx", namePrefix: "GPX", group: "gpx")
    
    let tracks = gpx.tracks.flatMap {track in
      track.segments.map {trackSegment in
        [
          "type": "Feature",
          "geometry": [
            "type": "LineString",
            "coordinates": trackSegment.points.map {trackPoint in
              [trackPoint.longitude!, trackPoint.latitude!]
            }
          ]
        ]
      }
    }
    
    let routes = gpx.routes.map {route in
      [
        "type": "Feature",
        "geometry": [
          "type": "LineString",
          "coordinates": route.points.map {routePoint in
            [routePoint.longitude!, routePoint.latitude!]
          }
        ]
      ]
    }
    
    let waypoints = gpx.waypoints.map {waypoint in
      [
        "type": "Feature",
        "geometry": [
          "type": "Point",
          "coordinates": [waypoint.longitude!, waypoint.latitude!]
        ]
      ]
    }
    
    let features: AnyCodable = [
      "type": "FeatureCollection",
      "features": tracks + routes + waypoints
    ]

    self.init(geoJSON: features, metadata: metadata)
  }
  
  init(geoJSON geojson: AnyCodable, metadata _metadata: LayerDefinition.Metadata? = nil){
    let metadata = _metadata ?? .random(idPrefix: "geojson", namePrefix: "GeoJSON", group: "gpx")
    
    let features = geoJSON(flatten: geojson)
    
    let featureMapping = [
      "circle": ["Point", "MultiPoint"],
      "line": ["LineString", "MultiLineString"],
      "fill": ["Polygon", "MultiPolygon"],
    ]
    
    let grouped = Dictionary(grouping: features) {(feature) -> String in
      guard let type = feature?.geometry?.type?.value as? String,
            let index = featureMapping.firstIndex(where: {(_, list) in list.contains(type) }) else {
        return "unknown"
      }
      
      return featureMapping.keys[index]
    }
    
    let featureCollections = grouped.mapValues({[
      "type": "FeatureCollection",
      "features": $0
    ]})
    
    var sources: [String: AnyCodable] = [:]
    var layers: [AnyCodable] = []
    
    if let data = featureCollections["line"] {
      let lineKey = metadata.id + "_line"
      
      sources[lineKey] = [
        "type": "geojson",
        "data": data
      ]
      
      layers.append([
        "id": lineKey,
        "source": lineKey,
        "type": "line",
        "layout": [
          "line-cap": "round",
          "line-join": "round"
        ],
        "paint": [
          "line-color": "#" + UIColor.randomSystemColor().toHex()!,
          "line-width": [
            "interpolate",
            ["linear"], ["zoom"],
            5, 1,
            10, 3,
            16, 5
          ]
        ]
      ])
    }
    
    if let data = featureCollections["circle"] {
      let circleKey = metadata.id + "_circle"
      
      sources[circleKey] =  [
        "type": "geojson",
        "data": data
      ]
      
      layers.append([
        "id": circleKey,
        "source": circleKey,
        "type": "circle",
        "paint": [
          "circle-color": "#" + UIColor.randomSystemColor().toHex()!,
          "circle-radius": [
            "interpolate",
            ["linear"], ["zoom"],
            5, 3,
            10, 5,
            16, 8
          ]
        ]
      ])
    }
    
    if let data = featureCollections["fill"] {
      let fillKey = metadata.id + "_fill"
      
      sources[fillKey] = [
        "type": "geojson",
        "data": data
      ]
      
      layers.append([
        "id": fillKey,
        "source": fillKey,
        "type": "fill",
        "paint": [
          "fill-color": "#" + UIColor.randomSystemColor().toHex()!
        ]
      ])
    }
    
    self.init(
      metadata: metadata,
      style: Style(
        sources: sources,
        layers: layers
      )
    )
  }
}
