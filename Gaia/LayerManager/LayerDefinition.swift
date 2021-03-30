import Foundation
import UIKit

import CoreGPX

struct LayerDefinition: Codable {
  let metadata: Metadata
  
  let style: Style
  
  struct Metadata: Codable {
    let id: String
    let name: String
    let group: String
    let groupIndex: Int
  }
}


extension LayerDefinition.Metadata {
  init(layer: Layer){
    self.init(
      id: layer.id,
      name: layer.name,
      group: layer.group,
      groupIndex: Int(layer.groupIndex)
    )
  }
}

extension LayerDefinition {
  init(layer: Layer){
    self.init(
      metadata: Metadata(layer: layer),
      style: layer.style
    )
  }
  
  init(xyzURL: String){
    let id = "xyz_" + randomString(length: 6)
    
    self.init(
      metadata: LayerDefinition.Metadata(
        id: id,
        name: "XYZ Import",
        group: "",
        groupIndex: 0
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
            "properties": [
              "colour": "#" + UIColor.randomSystemColor().toHex()!
            ],
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
      metadata: LayerDefinition.Metadata(
        id: id,
        name: name,
        group: "gpx",
        groupIndex: 0
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
              "line-color": ["get", "colour"],
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

