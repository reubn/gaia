import Mapbox

extension MGLMapView {
  public func setVisibleCoordinateBounds(_ bounds: MGLCoordinateBounds, sensible: Bool, minZoom: Double? = nil, animated: Bool){
    if(!sensible) {
      return setVisibleCoordinateBounds(bounds, animated: animated)
    }
    
    if(visibleCoordinateBounds.intersects(with: bounds)){
      return //  bounds already visible
    }
    
    let currentSpan = visibleCoordinateBounds.span
    let boundsSpan = bounds.span
    
    if(boundsSpan.latitudeDelta <= currentSpan.latitudeDelta && boundsSpan.longitudeDelta <= currentSpan.longitudeDelta){
      setCenter(bounds.center, animated: animated) // can fit bounds at current zoom so center bounds
    } else {
      let camera = cameraThatFitsCoordinateBounds(bounds) // else fit bounds normally
      
      if(minZoom != nil){
        let zoomIfPurelyFitting = MGLZoomLevelForAltitude(camera.altitude, 0, bounds.center.latitude, self.bounds.size)
        
        if(zoomIfPurelyFitting < minZoom! - 2.5){
          camera.altitude = MGLAltitudeForZoomLevel(minZoom! - 2.4, 0, bounds.center.latitude, self.bounds.size)
        }
      }
      
      setCamera(camera, animated: animated)
    }
  }
}
