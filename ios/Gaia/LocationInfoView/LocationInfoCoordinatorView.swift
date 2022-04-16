import Foundation
import UIKit

import Mapbox

class LocationInfoCoordinatorView: CoordinatorView, PanelDelegate, MapViewStyleDidChangeDelegate {
  unowned let panelViewController: LocationInfoPanelViewController
  
  var location: LocationInfoType
  var coordinate: CLLocationCoordinate2D {
    switch location {
      case .user: return MapViewController.shared.mapView.userLocation!.coordinate
      case .map(let coordinate):  return coordinate
      case .marker(let marker): return marker.coordinate
    }
  }
  
  
  var mapSource: MGLSource {
    get {
      MapViewController.shared.mapView.style?.source(withIdentifier: "location") ?? {
        let source = MGLShapeSource(identifier: "location", features: [], options: nil)
        
        MapViewController.shared.mapView.style?.addSource(source)
        
        return source
      }()
    }
  }
  
  var mapLayer: MGLStyleLayer {
    get {
      MapViewController.shared.mapView.style?.layer(withIdentifier: "location") ?? {
        let layer = MGLSymbolStyleLayer(identifier: "location", source: mapSource)
        
        MapViewController.shared.mapView.style?.addLayer(layer)
        
        return layer
      }()
    }
  }
 
  init(panelViewController: LocationInfoPanelViewController, location: LocationInfoType){
    self.panelViewController = panelViewController
    self.location = location
    
    super.init()
    
    self.panelViewController.panelDelegate = self
    
    story = [
      LocationInfoHome(coordinatorView: self),
      LocationInfoMarkerRename(coordinatorView: self)
    ]
    
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.add(delegate: self)
    
    super.ready()
    
    update(location: location)
  }
  
  
  override func panelDidDisappear() {
    super.panelDidDisappear()
    
    removePointsFromMap()
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.remove(delegate: self)
  }
  
  func update(location: LocationInfoType){
    self.location = location
    
    switch location {
      case .user:
        removePointsFromMap()
      case .marker, .map:
        handlePointUpdate()
    }

    currentChapter?.update(data: location)
  }
  
  func addMarker(coordinate: CLLocationCoordinate2D, colour: UIColor = MarkerManager.shared.latestColour){
    let newMarker = Marker(coordinate: coordinate, colour: colour)
    
    update(location: .marker(newMarker))
    MarkerManager.shared.markers.append(newMarker)
  }
  
  func removeMarker(_ marker: Marker){
    self.update(location: .map(marker.coordinate))
    
    if let index = MarkerManager.shared.markers.firstIndex(of: marker) {
      MarkerManager.shared.markers.remove(at: index)
    } else {
      print("remove", "marker not found!!!!", marker.id.uuidString)
    }
  }
  
  func changeMarker(_ marker: Marker, colour: UIColor){
    changeMarker(marker, colour: colour, title: marker.title)
  }
  
  func changeMarker(_ marker: Marker, title: String?){
    changeMarker(marker, colour: marker.colour, title: title)
  }
  
  func changeMarker(_ marker: Marker, colour: UIColor, title: String?){
    MarkerManager.shared.latestColour = colour
    
    let newMarker = Marker(marker: marker, colour: colour, title: title)
    
    print("change colour", marker.id, newMarker.id)
    
    self.update(location: .marker(newMarker))
    
    if let index = MarkerManager.shared.markers.firstIndex(of: marker) {
      MarkerManager.shared.markers[index] = newMarker
    } else {
      print("change colour", "marker not found!!!!", marker.id.uuidString)
    }
  }
  
  private var markerImageMap: [UIColor: UIImage] = [:]
  
  func getMarkerImage(colour: UIColor) -> String {
    let key = String(colour.hashValue)
    
    if(markerImageMap[colour] == nil) {
      let front = UIImage(named: "mapPin")!.withTintColor(colour)
      let back = UIImage(named: "mapPinBack")!
      let image = front.draw(inFrontOf: back)
      
      markerImageMap[colour] = image
    }
    
    MapViewController.shared.mapView.style?.setImage(markerImageMap[colour]!, forName: key)
    
    return key
  }
  
  func handlePointUpdate() {
    if !MapViewController.shared.mapView.visibleCoordinateBounds.contains(coordinate: coordinate) {
      MapViewController.shared.mapView.setCenter(coordinate, animated: true)
    }
    
    displayOnMap()
  }
  
  func displayOnMap(){
    if case .user = location {
      print("skipping, display point as location is for user")
      return
    }
    
    let point = MGLPointFeature()
    point.coordinate = coordinate
    
    (mapSource as! MGLShapeSource).shape = point
    
    let colour: UIColor
    
    if case .marker(let marker) = location {
      colour = marker.colour
    } else {
      colour = .systemGray
    }
    
    let layer = (mapLayer as! MGLSymbolStyleLayer)
    
    layer.iconImageName = NSExpression(forConstantValue: getMarkerImage(colour: colour))
    layer.iconScale = NSExpression(forConstantValue: 0.5)
  }
  
  func removePointsFromMap(){
    MapViewController.shared.mapView.style?.removeSource(mapSource)
    MapViewController.shared.mapView.style?.removeLayer(mapLayer)
  }
  
  func styleDidChange() {
    displayOnMap()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

enum LocationInfoType: Equatable {
  case user
  case map(CLLocationCoordinate2D)
  case marker(Marker)
}
