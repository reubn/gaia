import Foundation

@_spi(Experimental)import MapboxMaps
import Mapbox

extension MapView {
  func fixTransparency(){
    let metalView = (self.subviews.first(where: {$0 as? MTKView != nil}) as! MTKView)
    metalView.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
    metalView.isOpaque = false
  }
  
  var visibleCoordinateBounds: MGLCoordinateBounds {
    MGLCoordinateBounds(mapboxMap.coordinateBounds(for: bounds))
  }
}
