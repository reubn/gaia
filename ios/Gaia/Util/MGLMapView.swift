import Mapbox

extension MGLMapView {
  public func setVisibleCoordinateBounds(_ bounds: MGLCoordinateBounds, sensible: Bool, minZoom: Double? = nil, alwaysShowWhole: Bool = false, edgePadding: UIEdgeInsets? = nil, animated: Bool){
    if(!sensible) {
      return setVisibleCoordinateBounds(bounds, edgePadding: edgePadding, animated: animated)
    }
    
    if(!alwaysShowWhole && visibleCoordinateBounds.intersects(with: bounds)){
      return //  bounds already visible
    }
    
    let fitCamera = cameraThatFitsCoordinateBounds(bounds, edgePadding: edgePadding)
    
    if let coordinate = userLocation?.location?.coordinate, bounds.contains(coordinate: coordinate) {
      fitCamera.centerCoordinate = coordinate // if user is in the bounds, center on them not the bounds center
    } else {
      userTrackingMode = .none // fixes snapping back to user location
    }
    
    let fitCameraZoom = zoom(altitude: fitCamera.altitude, center: fitCamera.centerCoordinate)
    
    if(fitCameraZoom >= zoomLevel){
      fitCamera.altitude = altitude(zoom: zoomLevel, center: fitCamera.centerCoordinate) // if fit zoom could contian bounds, leave zoom as current
    } else if minZoom != nil, fitCameraZoom < minZoom! - 2.5 {
      fitCamera.altitude = altitude(zoom: minZoom! - 2.4, center: fitCamera.centerCoordinate) // if fit zoom is below minimum zoom, set to minZoom
    } else {} // otherwise stick with the fit zoom

    setCamera(fitCamera, animated: animated)
  }
  
  public func cameraThatFitsCoordinateBounds(_ bounds: MGLCoordinateBounds, edgePadding: UIEdgeInsets? = nil) -> MGLMapCamera {
    guard let edgePadding = edgePadding else {
      return cameraThatFitsCoordinateBounds(bounds)
    }
    
    return cameraThatFitsCoordinateBounds(bounds, edgePadding: edgePadding)
  }
  
  public func setVisibleCoordinateBounds(_ bounds: MGLCoordinateBounds, edgePadding: UIEdgeInsets? = nil, animated: Bool){
    guard let edgePadding = edgePadding else {
      return setVisibleCoordinateBounds(bounds, animated: animated)
    }
    
    return setVisibleCoordinateBounds(bounds, edgePadding: edgePadding, animated: animated, completionHandler: nil)
  }
  
  public func altitude(zoom: Double, center: CLLocationCoordinate2D) -> CLLocationDistance {
    MGLAltitudeForZoomLevel(zoom, 0, center.latitude, bounds.size)
  }
  
  public func zoom(altitude: CLLocationDistance, center: CLLocationCoordinate2D) -> Double {
    MGLZoomLevelForAltitude(altitude, 0, center.latitude, bounds.size)
  }
}
