import Foundation
import UIKit

import Mapbox

class LocationInfoCoordinatorView: CoordinatorView, PanelDelegate {
  unowned let panelViewController: LocationInfoPanelViewController
 
  init(panelViewController: LocationInfoPanelViewController){
    self.panelViewController = panelViewController
    
    super.init()
    
    self.panelViewController.panelDelegate = self
    
    story = [
      LocationInfoHome(coordinatorView: self, location: self.panelViewController.location),
      LocationInfoMarkerRename(coordinatorView: self)
    ]
    
    super.ready()
  }
  
  func update(location: LocationInfoType){
    goTo(0, data: location)
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
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




