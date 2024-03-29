import Foundation
import UIKit

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: PanelViewController, UserLocationDidUpdateDelegate, MapViewTappedDelegate, SelectableLabelPasteDelegate, MapViewStyleDidChangeDelegate {
  var location: LocationInfoType
  var titleCoordinate: CoordinateFormat? {
    didSet {
      switch titleCoordinate! {
        case .decimal(let coordinate):
          self.popoverTitle.text = coordinate.format(.decimal(.low))
          self.popoverTitle.selectionText = coordinate.format(.decimal(.high))
        case .sexagesimal(let coordinate):
          self.popoverTitle.text = coordinate.format(.sexagesimal(.low))
          self.popoverTitle.selectionText = coordinate.format(.sexagesimal(.low))
        case .gridReference(let coordinate):
          self.popoverTitle.text = coordinate.format(.gridReference(.low))
          self.popoverTitle.selectionText = coordinate.format(.gridReference(.low))
      }
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
        
        let front = UIImage(named: "mapPin")!.withTintColor(.systemPink)
        let back = UIImage(named: "mapPinBack")!
      
        let image = front.draw(inFrontOf: back)
        MapViewController.shared.mapView.style?.setImage(image, forName: "location")
         
        layer.iconImageName = NSExpression(forConstantValue: "location")
        layer.iconScale = NSExpression(forConstantValue: 0.5)
        
        MapViewController.shared.mapView.style?.addLayer(layer)
        
        return layer
      }()
    }
  }
  
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
    display.leftAnchor.constraint(equalTo: headingDisplay.rightAnchor, constant: 8).isActive = true
    display.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return display
  }()
  
  lazy var bearingDisplay: BearingDisplay = {
    let display = BearingDisplay()
    
    mainView.addSubview(display)
    
    display.translatesAutoresizingMaskIntoConstraints = false
    display.leftAnchor.constraint(equalTo: mainView.leftAnchor).isActive = true
    display.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return display
  }()
  
  lazy var distanceDisplay: DistanceDisplay = {
    let display = DistanceDisplay()
    
    mainView.addSubview(display)
    
    display.translatesAutoresizingMaskIntoConstraints = false
    display.leftAnchor.constraint(equalTo: bearingDisplay.rightAnchor, constant: 8).isActive = true
    display.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
    
    return display
  }()
  
  lazy var _allMetricDisplays = [headingDisplay, elevationDisplay, bearingDisplay, distanceDisplay]
  lazy var metricDisplays: [MetricDisplay] = [] {
    didSet {
      for metricDisplay in _allMetricDisplays {
        metricDisplay.isHidden = !metricDisplays.contains(metricDisplay)
      }
    }
  }
  
  init(location: LocationInfoType){
    self.location = location
    
    super.init(title: "")
    self.popoverTitle.pasteDelegate = self
    
    
    let labelTap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
    self.popoverTitle.isUserInteractionEnabled = true
    self.popoverTitle.addGestureRecognizer(labelTap)
    
    self.panelButtons = [.share, /*.star,*/ .dismiss]
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    update(location: location)
    
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    userLocationDidUpdate()
    
    MapViewController.shared.multicastMapViewTappedDelegate.add(delegate: self)
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.add(delegate: self)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    removePointsFromMap()
  }
  
  func styleDidChange() {
    if case .map(let coordinate) = location {
      displayPointOnMap(coordinate: coordinate)
    }
  }
  
  func userDidPaste(content: String) {
    let coordinate = CLLocationCoordinate2D(content)
    
    if(coordinate != nil){
      update(location: .map(coordinate!))
    }
  }

  func update(location: LocationInfoType){
    self.location = location
    
    switch location {
      case .user:
        metricDisplays = [headingDisplay, elevationDisplay]
        
        userLocationDidUpdate()
        removePointsFromMap()
      case .map(let coordinate):
        if case .map(let coordinate) = location, !MapViewController.shared.mapView.visibleCoordinateBounds.contains(coordinate: coordinate) {
          MapViewController.shared.mapView.setCenter(coordinate, animated: true)
        }
        
        updateTitleCoordinate(coordinate)
        displayPointOnMap(coordinate: coordinate)
        
        metricDisplays = [bearingDisplay, distanceDisplay]

        var distanceValue = (distanceDisplay.value as! CoordinatePair)
        distanceValue.a = coordinate
        distanceDisplay.value = distanceValue

        var bearingValue = (bearingDisplay.value as! CoordinatePair)
        bearingValue.a = coordinate
        bearingDisplay.value = bearingValue

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }
  
  func displayPointOnMap(coordinate: CLLocationCoordinate2D){
    let point = MGLPointFeature()
    point.coordinate = coordinate
 
    (mapSource as! MGLShapeSource).shape = point
    _ = mapLayer
  }
  
  func removePointsFromMap(){
    MapViewController.shared.mapView.style?.removeSource(mapSource)
    MapViewController.shared.mapView.style?.removeLayer(mapLayer)
  }
  
  func userLocationDidUpdate() {
    if(MapViewController.shared.mapView.userLocation == nil) {return}
    
    let coordinate = MapViewController.shared.mapView.userLocation!.coordinate
    let heading = MapViewController.shared.mapView.userLocation!.heading
    let location = MapViewController.shared.mapView.userLocation!.location
    
    if case .user = self.location {
      updateTitleCoordinate(coordinate)
    } else {
      var distanceValue = (distanceDisplay.value as! CoordinatePair)
      distanceValue.b = coordinate
      distanceDisplay.value = distanceValue

      var bearingValue = (bearingDisplay.value as! CoordinatePair)
      bearingValue.b = coordinate
      bearingDisplay.value = bearingValue
    }
    
    self.headingDisplay.value = heading
    self.elevationDisplay.value = location
  }
  
  override func panelButtonTapped(button: PanelButtonType) {
    super.panelButtonTapped(button: button)
    
    let panelButton = getPanelButton(button)
    
    if(button == .share){
      showShareSheet(panelButton)
    }
  }

  func mapViewTapped(){
    if case .map = location {
      dismiss(animated: true, completion: nil)
    }
  }
  
  func updateTitleCoordinate(_ coordinate: CLLocationCoordinate2D){
    switch titleCoordinate {
      case .decimal(_): titleCoordinate = .decimal(coordinate)
      case .sexagesimal(_): titleCoordinate = .sexagesimal(coordinate)
      case .gridReference(_): titleCoordinate = .gridReference(coordinate)
        
      case nil: titleCoordinate = .decimal(coordinate)
    }
  }
  
  @objc func labelTapped(){
    switch titleCoordinate! {
      case .decimal(let coordinate): titleCoordinate = .sexagesimal(coordinate)
      case .sexagesimal(let coordinate): titleCoordinate = .gridReference(coordinate)
      case .gridReference(let coordinate): titleCoordinate = .decimal(coordinate)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


enum LocationInfoType {
  case user
  case map(CLLocationCoordinate2D)
//  case pinned
}

enum CoordinateFormat {
  case decimal(CLLocationCoordinate2D)
  case sexagesimal(CLLocationCoordinate2D)
  case gridReference(CLLocationCoordinate2D)
}
