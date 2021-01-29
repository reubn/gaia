import Foundation
import UIKit

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: MapViewPanelViewController, UserLocationDidUpdateDelegate {
  let mapViewController: MapViewController
  lazy var mainView = UIView()
  
  lazy var headingDisplay: SelectableLabel = {
    let label = SelectableLabel()
    label.isSelectable = true
    
    label.font = UIFont.systemFont(ofSize: 18)
    label.textColor = .secondaryLabel
    
    mainView.addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: mainView.leftAnchor).isActive = true
    label.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return label
  }()
  
  lazy var altitudeDisplay: SelectableLabel = {
    let label = SelectableLabel()
    label.isSelectable = true
    
    label.font = UIFont.systemFont(ofSize: 18)
    label.textColor = .secondaryLabel
    
    mainView.addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: mainView.centerXAnchor).isActive = true
    label.rightAnchor.constraint(equalTo: mainView.rightAnchor).isActive = true
    label.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return label
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
    
    let location = mapViewController.mapView.userLocation!.coordinate
    let heading = mapViewController.mapView.userLocation!.heading
    let altitude = mapViewController.mapView.userLocation!.location!.altitude
    
    let lat = Double(location.latitude)
    let lng = Double(location.longitude)
    
    self.popoverTitle.text = String(format: "%.4f, %.4f", lat, lng) // 11m worst-case
    self.popoverTitle.textToSelect = String(format: "%.6f, %.6f", lat, lng) // 11cm worst-case
    
    if(heading != nil) {
      self.headingDisplay.text = String(format: "🧭 %03d° 🧲 %03d°", Int(heading!.trueHeading), Int(heading!.magneticHeading))
      self.headingDisplay.textToSelect = String(format: "T: %03d° M: %03d°", Int(heading!.trueHeading), Int(heading!.magneticHeading))
    }
    
    let altitudeString = String(format: "%dm", Int(altitude))
    self.altitudeDisplay.text = "⛰ " + altitudeString
    self.altitudeDisplay.textToSelect = altitudeString
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
