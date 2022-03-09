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
  }
}

extension LayerDefinition.Metadata {
  init(layer: GaiaLayer){
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
  init(layer: GaiaLayer){
    self.init(
      groupIndex: Int(layer.groupIndex),
      
      pinned: layer.pinned,
      enabled: layer.enabled,
      quickToggle: layer.quickToggle
    )
  }
}

extension LayerDefinition {
  init(layer: GaiaLayer){
    self.init(
      metadata: Metadata(layer: layer),
      user: User(layer: layer),
      style: layer.style
    )
  }
  
  init(style: Style){
    let random = randomString(length: 3)
    let id = "style_" + random
    
    self.init(
      metadata: Metadata(
        id: id,
        name: "Import " + random,
        group: ""
      ),
      style: style
    )
  }
  
  init(xyzURL: String){
    let random = randomString(length: 3)
    let id = "xyz_" + random
    
    self.init(
      metadata: Metadata(
        id: id,
        name: "XYZ Import" + random,
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
    
    let waypoints = gpx.waypoints.map {waypoint in
      [
        "type": "Feature",
        "geometry": [
          "type": "Point",
          "coordinates": [waypoint.longitude!, waypoint.latitude!]
        ]
      ]
    }
    
    let metadata = Metadata(id: id, name: name, group: "gpx")
    
    let features: AnyCodable = [
      "type": "FeatureCollection",
      "features": tracks + waypoints
    ]

    self.init(geoJSON: features, metadata: metadata)
  }
  
  init(geoJSON geojson: AnyCodable, metadata: Metadata?=nil){
    let random = randomString(length: 3)
    
    let name = metadata?.name ?? "GeoJSON Import \(random)"
    let id = metadata?.id ?? "geojson_" + random
    
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
            5, 3,
            10, 5,
            16, 8
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
      metadata: metadata ?? Metadata(
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
