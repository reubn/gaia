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
}