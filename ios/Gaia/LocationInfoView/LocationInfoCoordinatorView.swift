import Foundation
import UIKit

import Mapbox

fileprivate var bubbleImageMap: [UIColor: UIImage] = [:]

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
  
  var bubbleSource: MGLShapeSource {
    get {
      MapViewController.shared.mapView.style?.source(withIdentifier: "location") as? MGLShapeSource ?? {
        let source = MGLShapeSource(identifier: "location", features: [], options: nil)
        
        MapViewController.shared.mapView.style?.addSource(source)
        
        return source
      }()
    }
  }
  
  var bubbleLayer: MGLSymbolStyleLayer {
    get {
      MapViewController.shared.mapView.style?.layer(withIdentifier: "location") as? MGLSymbolStyleLayer ?? {
        let layer = MGLSymbolStyleLayer(identifier: "location", source: bubbleSource)
        
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
    
    hideBubble()
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.remove(delegate: self)
  }
  
  func update(location: LocationInfoType){
    self.location = location
    
    switch location {
      case .user: hideBubble()
      case .marker, .map: showBubble(firstTime: true)
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
  
  func getBubbleImage(colour: UIColor) -> (key: String, image: UIImage) {
    let key = String(colour.hashValue)
    
    if(bubbleImageMap[colour] == nil) {
      let front = UIImage(named: "mapPin")!.withTintColor(colour)
      let back = UIImage(named: "mapPinBack")!
      let image = front.draw(inFrontOf: back)
      
      bubbleImageMap[colour] = image
    }
    
    MapViewController.shared.mapView.style?.setImage(bubbleImageMap[colour]!, forName: key)
    
    return (key: key, image: bubbleImageMap[colour]!)
  }

  func showBubble(firstTime: Bool = true){
    let colour: UIColor
    
    if case .marker(let marker) = location {
      colour = marker.colour
    } else {
      colour = .systemGray
    }
    
    let bubbleImage = getBubbleImage(colour: colour)
    let bubbleImageSize = bubbleImage.image.size
    
    let xPadding = bubbleImageSize.width / 8
    let topPadding = (bubbleImageSize.height / 4) - 10
    let bottomPadding = locationInfoPanelTipBottomInset + 2
    
    let insets = UIEdgeInsets(top: topPadding, left: xPadding, bottom: bottomPadding, right: xPadding)
    
    let safeRect = MapViewController.shared.mapView.bounds
      .inset(by: MapViewController.shared.mapView.safeAreaInsets)
      .inset(by: insets)
    let safeBounds = MapViewController.shared.mapView.convert(safeRect, toCoordinateBoundsFrom: MapViewController.shared.mapView)
 
    if firstTime && !safeBounds.contains(coordinate: coordinate) {
      MapViewController.shared.mapView.setCenter(coordinate, animated: true)
    }
    
    let point = MGLPointFeature()
    point.coordinate = coordinate
    
    bubbleSource.shape = point
    
    bubbleLayer.iconImageName = NSExpression(forConstantValue: bubbleImage.key)
    bubbleLayer.iconScale = NSExpression(forConstantValue: 0.5)
  }
  
  func hideBubble(){
    MapViewController.shared.mapView.style?.removeSource(bubbleSource)
    MapViewController.shared.mapView.style?.removeLayer(bubbleLayer)
  }
  
  func styleDidChange() {
    showBubble(firstTime: false)
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
