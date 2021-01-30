import Foundation
import UIKit

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: MapViewPanelViewController, UserLocationDidUpdateDelegate {
  let mapViewController: MapViewController
  lazy var mainView = UIView()
  
  lazy var headingDisplay: HeadingDisplay = {
    let display = HeadingDisplay()
    
    mainView.addSubview(display)
    
    display.translatesAutoresizingMaskIntoConstraints = false
    display.leftAnchor.constraint(equalTo: mainView.leftAnchor).isActive = true
    display.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return display
  }()

  lazy var elevationDisplay: ElevationDisplay = {
    let display = ElevationDisplay()
    
    mainView.addSubview(display)
    
    display.translatesAutoresizingMaskIntoConstraints = false
    display.leftAnchor.constraint(equalTo: headingDisplay.rightAnchor, constant: 5).isActive = true
    display.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return display
  }()
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    super.init(title: "Current Location")
    self.popoverTitle.isSelectable = true
    
    self.buttons = [.star, .dismiss]
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    mapViewController.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    
    userLocationDidUpdate()
  }
  
  func userLocationDidUpdate() {
    if(mapViewController.mapView.userLocation == nil) {return}
    
    let coordinate = mapViewController.mapView.userLocation!.coordinate
    let heading = mapViewController.mapView.userLocation!.heading
    let location = mapViewController.mapView.userLocation!.location
    
    let lat = Double(coordinate.latitude)
    let lng = Double(coordinate.longitude)
    
    self.popoverTitle.text = String(format: "%.4f, %.4f", lat, lng) // 11m worst-case
    self.popoverTitle.textToSelect = String(format: "%.6f, %.6f", lat, lng) // 11cm worst-case
    
    if(heading != nil) {
      self.headingDisplay.value = heading!
    }
    
    if(location != nil) {
      self.elevationDisplay.value = location!
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
