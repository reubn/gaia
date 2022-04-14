import Foundation
import UIKit

import Mapbox
import FloatingPanel
import CoreLocation

class LocationInfoPanelViewController: PanelViewController, UserLocationDidUpdateDelegate, SelectableLabelPasteDelegate, MapViewStyleDidChangeDelegate {
  let pinButton = PanelSmallButton(.init(systemName: "mappin", colour: .systemPink))
  
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
  
  var defferedMenuElement: UIDeferredMenuElement {
    UIDeferredMenuElement.uncached({completion in
      
      let colours: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemPink]
      
      let makeColourActions = {(callback: @escaping (UIColor) -> Void) -> [UIAction] in
        colours.map({colour in
          UIAction(
            title: colour.accessibilityName,
            image: UIImage(systemName: "circle.fill")?.withTintColor(colour).withRenderingMode(.alwaysOriginal)) {_ in
              callback(colour)
            }
        })
      }
      
      let actions: [UIMenuElement]
      
      switch self.location {
        case .user, .map:
          actions = makeColourActions {colour in
            self.addMarker(colour: colour)
          }
        case .marker(let marker):
          let removePin = UIAction(
            title: "Remove Marker",
            image: UIImage(systemName: "mappin.slash")) {_ in
              self.removeMarker(marker)
            }
          
          let changeColourChildren = makeColourActions {colour in
            MarkerManager.shared.latestColour = colour
            
            let newMarker = Marker(marker: marker, colour: colour)
            
            print("change colour", marker.id, newMarker.id)
            
            self.update(location: .marker(newMarker))
            
            if let index = MarkerManager.shared.markers.firstIndex(of: marker) {
              MarkerManager.shared.markers[index] = newMarker
            } else {
              print("change colour", "marker not found!!!!", marker.id.uuidString)
            }
          }
          
          let colourMenu = UIMenu(title: "Change Colour", children: changeColourChildren)
          
          actions = [removePin, colourMenu]
      }
 
      completion(actions)
    })
  }
  
  init(location: LocationInfoType){
    self.location = location
    
    super.init(title: "")
    self.popoverTitle.pasteDelegate = self
    
    
    let labelTap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
    self.popoverTitle.isUserInteractionEnabled = true
    self.popoverTitle.addGestureRecognizer(labelTap)
    
    self.panelButtons = [.share, .custom(pinButton), .dismiss]
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    update(location: location)
    
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    userLocationDidUpdate()
    
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.add(delegate: self)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    removePointsFromMap()
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.remove(delegate: self)
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.remove(delegate: self)
  }
  
  func styleDidChange() {
    displayOnMap()
  }
  
  func userDidPaste(content: String) {
    let coordinate = CLLocationCoordinate2D(content)
    
    if(coordinate != nil){
      update(location: .map(coordinate!))
    }
  }

  func update(location: LocationInfoType){
    self.location = location
    
    print("location update", location)
    updatePinButton()
    
    switch location {
      case .user:
        metricDisplays = [headingDisplay, elevationDisplay]
        
        userLocationDidUpdate()
        removePointsFromMap()
      case .marker, .map:
        handlePointUpdate()
    }
  }
        
  var coordinate: CLLocationCoordinate2D {
    switch location {
      case .user: return MapViewController.shared.mapView.userLocation!.coordinate
      case .map(let coordinate):  return coordinate
      case .marker(let marker): return marker.coordinate
    }
  }
  
  func updatePinButton(){
    pinButton.showsMenuAsPrimaryAction = false
    pinButton.menu = UIMenu(title: "", children: [defferedMenuElement])
    
    switch location {
      case .user, .map: pinButton.setDisplayConfig(.init(systemName: "mappin", colour: MarkerManager.shared.latestColour))
      case .marker(let marker): pinButton.setDisplayConfig(.init(systemName: "mappin.slash", colour: marker.colour))
    }
  }
  
  func handlePointUpdate() {
    if !MapViewController.shared.mapView.visibleCoordinateBounds.contains(coordinate: coordinate) {
      MapViewController.shared.mapView.setCenter(coordinate, animated: true)
    }
    
    updateTitleCoordinate(coordinate)
    displayOnMap()
    
    metricDisplays = [bearingDisplay, distanceDisplay]
    
    var distanceValue = (distanceDisplay.value as! CoordinatePair)
    distanceValue.a = coordinate
    distanceDisplay.value = distanceValue
    
    var bearingValue = (bearingDisplay.value as! CoordinatePair)
    bearingValue.a = coordinate
    bearingDisplay.value = bearingValue
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
  
  func addMarker(colour: UIColor = MarkerManager.shared.latestColour){
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
    } else if(button == .custom(pinButton)){
      switch location {
        case .user, .map: addMarker()
        case .marker(let marker): removeMarker(marker)
      }
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


enum LocationInfoType: Equatable {
  case user
  case map(CLLocationCoordinate2D)
  case marker(Marker)
}

enum CoordinateFormat {
  case decimal(CLLocationCoordinate2D)
  case sexagesimal(CLLocationCoordinate2D)
  case gridReference(CLLocationCoordinate2D)
}
