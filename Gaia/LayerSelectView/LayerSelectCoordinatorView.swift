import Foundation
import UIKit

import AnyCodable
import Mapbox
import CoreGPX


class LayerSelectCoordinatorView: CoordinatorView {
  let mapViewController: MapViewController
  unowned let panelViewController: LayerSelectPanelViewController
  
  lazy var layerManager = mapViewController.layerManager
  
  init(mapViewController: MapViewController, panelViewController: LayerSelectPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init()
    
    story = [
      LayerSelectHome(coordinatorView: self, mapViewController: mapViewController),
      LayerSelectImport(coordinatorView: self, mapViewController: mapViewController)
    ]
    
    super.ready()
  }
  
  func done(data: Data){
    do {
      let decoder = JSONDecoder()

      let contents = try decoder.decode([LayerDefinition].self, from: data)
      
      print(contents)
      
      DispatchQueue.main.async {
        for layerDefinition in contents {
          _ = self.layerManager.newLayer(layerDefinition)
        }
        
        self.layerManager.saveLayers()
        super.done()
      }
    } catch {
      let gpx = GPXParser(withData: data).parsedData()
      
      if(gpx != nil) {
        let features: [String: Any] = [
          "type": "FeatureCollection",
          "features": gpx!.tracks.flatMap {track in
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
        
        let id = "gpx_" + randomString(length: 6)
        let layerDefinition = LayerDefinition(
          metadata: LayerDefinition.Metadata(
            id: id,
            name: id,
            group: "overlay",
            groupIndex: 0
          ),
          styleJSON: StyleJSON(
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
        
      _ = self.layerManager.newLayer(layerDefinition)
      
      self.layerManager.saveLayers()
      super.done()
      }
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
