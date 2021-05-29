import Foundation

import Mapbox

let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

let layerSupportsOpacity = {(layer: Style.Layer) -> Bool in
  ["line", "raster"].contains(layer.type?.value as? String)
}

let layerSupportsColour = {(layer: Style.Layer) -> Bool in
  ["line"].contains(layer.type?.value as? String)
}

struct Style: Codable, Equatable {
  var version = 8
  
  typealias Source = AnyCodable
  typealias Layer = AnyCodable
  
  var sources: [String: Source]
  var layers: [Layer]
  
  typealias Sprite = String
  typealias Glyphs = String
  typealias Terrain = AnyCodable
  
  var sprite: Sprite? = nil
  var glyphs: Glyphs? = nil
  var terrain: Terrain? = nil
 
  struct BoundsInfo {
    let individual: [MGLCoordinateBounds]
    let superbound: MGLCoordinateBounds?
  }
  
  var zoomLevelsCovered: (min: Double, max: Double) {
    var mins: [Double] = []
    var maxes: [Double] = []
    
    for (_, source) in sources {
      let minZoom = source.minzoom?.value
      let maxZoom = source.maxzoom?.value
      
      if(minZoom != nil) {
        mins.append(minZoom as? Double ?? Double(minZoom as! Int))
      }
      
      if(maxZoom != nil) {
        maxes.append(maxZoom as? Double ?? Double(maxZoom as! Int))
      }
    }

    return (
      min: mins.max() ?? 0,
      max: maxes.min() ?? 22
    )
  }
  
  var bounds: BoundsInfo {
    var allBounds: [MGLCoordinateBounds] = []
    
    var minLat: CLLocationDegrees?
    var minLon: CLLocationDegrees?
    
    var maxLat: CLLocationDegrees?
    var maxLon: CLLocationDegrees?
    
    for (id, source) in sources {
      let type = source.type?.value as? String
      
      if(type == "geojson"){
        print("calculating bounds for geojson source", id)
        let coords = source.data?.features?[0]?.geometry?.coordinates?.value as? [[CLLocationDegrees]] // support multiple features
        
        if(coords != nil){
          var featureMinLat: CLLocationDegrees?
          var featureMinLon: CLLocationDegrees?
          
          var featureMaxLat: CLLocationDegrees?
          var featureMaxLon: CLLocationDegrees?
          
          for latLon in coords! {
            let lat = latLon[1]
            let lon = latLon[0]
            
            featureMinLat = min(featureMinLat ?? lat, lat)
            featureMinLon = min(featureMinLon ?? lon, lon)
            
            featureMaxLat = max(featureMaxLat ?? lat, lat)
            featureMaxLon = max(featureMaxLon ?? lon, lon)
          }
          
          if(featureMinLat != nil){
            minLat = min(minLat ?? featureMinLat!, featureMinLat!)
            minLon = min(minLon ?? featureMinLon!, featureMinLon!)
            
            maxLat = max(maxLat ?? featureMaxLat!, featureMaxLat!)
            maxLon = max(maxLon ?? featureMaxLon!, featureMaxLon!)
            
            let sw = CLLocationCoordinate2D(latitude: featureMinLat!, longitude: featureMinLon!)
            let ne = CLLocationCoordinate2D(latitude: featureMaxLat!, longitude: featureMaxLon!)
            
            allBounds.append(MGLCoordinateBoundsMake(sw, ne))
          }
        }
      } else if(type == "raster" || type == "raster-dem" || type == "vector")  {
        let bounds = source.bounds?.value as? [CLLocationDegrees]
        
        if(bounds != nil && bounds!.count == 4) {
          let sw = CLLocationCoordinate2D(latitude: bounds![1], longitude: bounds![0])
          let ne = CLLocationCoordinate2D(latitude: bounds![3], longitude: bounds![2])
          
          minLat = min(minLat ?? bounds![1], bounds![1])
          minLon = min(minLon ?? bounds![0], bounds![0])
          
          maxLat = max(maxLat ?? bounds![3], bounds![3])
          maxLon = max(maxLon ?? bounds![2], bounds![2])
          
          allBounds.append(MGLCoordinateBoundsMake(sw, ne))
        } else {
          // if a raster, vector layer has no bounds, then assume its worldwide - therefore short circuit, discarding bounds
          return BoundsInfo(individual: [], superbound: nil)
        }
      }
    }
    
    var superbound: MGLCoordinateBounds?
    
    if(minLat != nil) {
      let sw = CLLocationCoordinate2D(latitude: minLat!, longitude: minLon!)
      let ne = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLon!)
      
      superbound = MGLCoordinateBoundsMake(sw, ne)
    }

    return BoundsInfo(individual: allBounds, superbound: superbound)
  }
  
  var url: URL? {
    do {
      let encoder = JSONEncoder()
      
      let data = try encoder.encode(self)
      
      let temporaryFilename = UUID().uuidString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  var supportsOpacity: Bool {
    layers.contains(where: layerSupportsOpacity)
  }
  
  var opacity: Double {
    layers.compactMap({layer -> Double? in
      let type = layer.type?.value as? String
      
      switch type {
        case "raster": return layer.paint?[dynamicMember: "raster-opacity"]?.value as? Double
        case "line": return layer.paint?[dynamicMember: "line-opacity"]?.value as? Double
        default: return nil
      }
    }).max() ?? 1
  }
  
  func with(opacity: Double) -> Self {
    var copy = self
    copy.layers = layers.map({
      var layer = $0
      
      let type = layer.type?.value as? String
      
      switch type {
        case "raster":
          layer.paint = layer.paint ?? AnyCodable([:])
          layer.paint?[dynamicMember: "raster-opacity"] = AnyCodable(opacity)
        case "line":
          layer.paint = layer.paint ?? AnyCodable([:])
          layer.paint?[dynamicMember: "line-opacity"] = AnyCodable(opacity)
        default: ()
      }
      
      
      return layer
    })
    
    return copy
  }
  
  var supportsColour: Bool {
    layers.contains(where: layerSupportsColour)
  }
  
  var colour: UIColor? {
    let layer = layers.first(where: layerSupportsColour)
    
    let type = layer?.type?.value as? String
    var string: String?
    
    switch type {
      case "line": string = layer?.paint?[dynamicMember: "line-color"]?.value as? String
      default: return nil
    }
    
    if(string != nil){
      return UIColor(hex: string!)
    }
    
    return nil
  }
  
  var colourWithAlpha: UIColor? {
    colour?.withAlphaComponent(CGFloat(opacity))
  }
  
  func with(colour: UIColor) -> Self {
    var copy = self
    
    let layerIndex = copy.layers.firstIndex(where: layerSupportsColour)
    if(layerIndex == nil) {
      return self
    }
    
    let type = copy.layers[layerIndex!].type?.value as? String
    let colourString = colour.toHex()
    
    if(colourString == nil) {
      return self
    }
    
    switch type {
      case "line": copy.layers[layerIndex!].paint?[dynamicMember: "line-color"]? = AnyCodable("#" + colour.toHex()!)
      default: ()
    }
    
    return copy
  }
}
