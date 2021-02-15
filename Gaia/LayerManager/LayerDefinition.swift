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
}

extension LayerDefinition {
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
  init(gpx: GPXRoot){
    let id = "gpx_" + randomString(length: 6)
            ]
          }
        }
      ]
      
    
    self.init(
      metadata: LayerDefinition.Metadata(
        id: id,
        name: "GPX Import",
        group: "overlay",
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
            "paint": [
              "line-color": ["get", "colour"],
              "line-width": 5
            ]
          ]
        ]
      )
    )
  }
}

