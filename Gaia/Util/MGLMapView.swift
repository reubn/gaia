import Mapbox

extension MGLMapView {
  public func setVisibleCoordinateBounds(_ bounds: MGLCoordinateBounds, sensible: Bool, animated: Bool){
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
      setVisibleCoordinateBounds(bounds, animated: animated) // else fit bounds normally
    }
  }
}
