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
      let marker: Marker?
      
      if case .marker(let _marker) = self.location {
        marker = _marker
      } else {
        marker = nil
      }
      
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
      
      if let marker = marker {
        let removePin = UIAction(
          title: "Remove Marker",
          image: UIImage(systemName: "mappin.slash")) {_ in
            print("remove marker", marker.id)
            if let index = MarkerManager.shared.markers.firstIndex(of: marker) {
              MarkerManager.shared.markers.remove(at: index)
              self.update(location: .map(marker.coordinate))
            }
          }
        
        let children = makeColourActions {colour in
          MarkerManager.shared.latestColour = colour
          if let index = MarkerManager.shared.markers.firstIndex(of: marker) {
            MarkerManager.shared.markers[index].colour = colour
            self.update(location: .marker(marker))
          }
        }
        
        let colourMenu = UIMenu(title: "Change Colour", children: children)
        
        actions = [removePin, colourMenu]
      } else {
        actions = makeColourActions {colour in
          MarkerManager.shared.latestColour = colour
          
          let newMarker = Marker(coordinate: self.coordinate, colour: colour)
          
          MarkerManager.shared.markers.append(newMarker)
          self.update(location: .marker(newMarker))
        }
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
    
    pinButton.menu = UIMenu(title: "", children: [defferedMenuElement])
    
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
  }
  
  func styleDidChange() {
    switch location {
      case .user: ()
      case .map(let coordinate): displayPointOnMap(coordinate: coordinate)
      case .marker(let marker): displayPointOnMap(coordinate: marker.coordinate)
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
    
    print("location update", location)
    
    switch location {
      case .user:
        metricDisplays = [headingDisplay, elevationDisplay]
        
        userLocationDidUpdate()
        removePointsFromMap()
        pinButton.showsMenuAsPrimaryAction = false
      case .marker(let marker):
        handlePointUpdate(coordinate: marker.coordinate)
        pinButton.showsMenuAsPrimaryAction = true
      case .map(let coordinate):
        handlePointUpdate(coordinate: coordinate)
        pinButton.showsMenuAsPrimaryAction = false
    }
  }
        
  var coordinate: CLLocationCoordinate2D {
    switch location {
      case .user: return MapViewController.shared.mapView.userLocation!.coordinate
      case .map(let coordinate):  return coordinate
      case .marker(let marker): return marker.coordinate
    }
  }
  
  func handlePointUpdate(coordinate: CLLocationCoordinate2D) {
    if !MapViewController.shared.mapView.visibleCoordinateBounds.contains(coordinate: coordinate) {
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
  
  private var markerImageSet: Set<UIColor> = []
  
  func getMarkerImage(colour: UIColor) -> String {
    let name = colour.toHex()!
    
    if (!markerImageSet.contains(colour)) {
      print("not cached")
      let front = UIImage(named: "mapPin")!.withTintColor(colour)
      let back = UIImage(named: "mapPinBack")!
      
      markerImageSet.insert(colour)
      MapViewController.shared.mapView.style?.setImage(front.draw(inFrontOf: back), forName: name)
    }
  
    return name
  }
  
  func displayPointOnMap(coordinate: CLLocationCoordinate2D){
    let point = MGLPointFeature()
    point.coordinate = coordinate
 
    (mapSource as! MGLShapeSource).shape = point
    
    let colour: UIColor
    
    if case .marker(let marker) = location {
      colour = marker.colour
    } else {
      colour = .systemPink
    }
  
    _ = mapLayer
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
      
      let newMarker = Marker(coordinate: self.coordinate, colour: MarkerManager.shared.latestColour ?? .systemPink)
      
      MarkerManager.shared.markers.append(newMarker)
      update(location: .marker(newMarker))
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
  case marker(Marker)
}

enum CoordinateFormat {
  case decimal(CLLocationCoordinate2D)
  case sexagesimal(CLLocationCoordinate2D)
  case gridReference(CLLocationCoordinate2D)
}
