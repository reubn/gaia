import Foundation
import UIKit

import CoreGPX

struct LayerDefinition: Codable {
  let metadata: Metadata
  var user: User? = User()
  
  let style: Style
  
  struct Metadata: Codable {
    let id: String
    let name: String
    let group: String
    var overrideUIMode: String? = nil
    
    var attribution: String? = nil
  }
  
  struct User: Codable {
    var groupIndex: Int = 0
    
    var pinned = false
    var enabled = true
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
}

extension LayerDefinition.User {
  init(layer: Layer){
    self.init(
      groupIndex: Int(layer.groupIndex),
      
      pinned: layer.pinned,
      enabled: layer.enabled
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
  
  init(xyzURL: String){
    let id = "xyz_" + randomString(length: 6)
    
    self.init(
      metadata: Metadata(
        id: id,
        name: "XYZ Import",
        group: ""
      ),
      style: Style(
        sources: [
          id: [
            "type": "raster",
            "tiles": [xyzURL]
          ]
        ],
        layers: [
          [
            "id": id,
            "source": id,
            "type": "raster"
          ]
        ]
      )
    )
  }
  
  init(gpx: GPXRoot){
    let random = randomString(length: 3)
    
    let name = gpx.metadata?.name ?? "GPX Import \(random)"
    let id = "gpx_" + random
    
    let features: [String: Any] = [
      "type": "FeatureCollection",
      "features": gpx.tracks.flatMap {track in
        track.tracksegments.map {trackSegment in
          [
            "type": "Feature",
            "geometry": [
              "type": "LineString",
              "coordinates": trackSegment.trackpoints.map {trackPoint in
                [trackPoint.longitude!, trackPoint.latitude!]
              }
            ]
          ]
        }
      }
    ]

    self.init(
      metadata: Metadata(
        id: id,
        name: name,
        group: "gpx"
      ),
      style: Style(
        sources: [
          id: [
            "type": "geojson",
            "data": features
          ]
        ],
        layers: [
          [
            "id": id,
            "source": id,
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
          ]
        ]
      )
    )
  }
  
  init(geoJSON geojson: AnyCodable){
    let random = randomString(length: 3)
    
    let name = "GeoJSON Import \(random)"
    let id = "geojson_" + random
    
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
      let lineKey = id + "_line"
      
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
      let circleKey = id + "_circle"
      
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
            5, 5,
            10, 8,
            16, 10
          ]
        ]
      ])
    }
    
    if let data = featureCollections["fill"] {
      let fillKey = id + "_fill"
      
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
      metadata: Metadata(
        id: id,
        name: name,
        group: "gpx"
      ),
      style: Style(
        sources: sources,
        layers: layers
      )
    )
  }
}
