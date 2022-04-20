import Foundation
import UIKit
import OrderedCollections

import Mapbox
import FloatingPanel
import CoreLocation
import CoreGPX

class LocationInfoHome: UIView, CoordinatedView, UserLocationDidUpdateDelegate, SelectableLabelPasteDelegate {
  unowned let coordinatorView: LocationInfoCoordinatorView
  
  let markerButton = PanelSmallButton(.init(icon: .systemName("plus"), colour: .systemPink))
  
  var location: LocationInfoType {
    coordinatorView.location
  }
  
  var coordinate: CLLocationCoordinate2D {
    coordinatorView.coordinate
  }
  
  var titleContent: TitleFormat? {
    didSet {
      switch titleContent! {
        case .coordinate(.decimal):
          coordinatorView.panelViewController.popoverTitle.text = coordinate.format(.decimal(.low))
          coordinatorView.panelViewController.popoverTitle.selectionText = coordinate.format(.decimal(.high))
        case .coordinate(.sexagesimal):
          coordinatorView.panelViewController.popoverTitle.text = coordinate.format(.sexagesimal(.low))
          coordinatorView.panelViewController.popoverTitle.selectionText = coordinatorView.panelViewController.popoverTitle.text
        case .coordinate(.gridReference):
          coordinatorView.panelViewController.popoverTitle.text = coordinate.format(.gridReference(.low, space: true))
          coordinatorView.panelViewController.popoverTitle.selectionText = coordinate.format(.gridReference(.high))
        case .title(let marker):
          coordinatorView.panelViewController.popoverTitle.text = marker.title ?? "Untitled"
          coordinatorView.panelViewController.popoverTitle.selectionText = coordinatorView.panelViewController.popoverTitle.text
      }
    }
  }
  
  lazy var labelTap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
  
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
    UIDeferredMenuElement.uncached({[unowned self] completion in
      
      let colours: OrderedDictionary<UIColor, String> = [
        .systemPink: "Pink",
        .systemPurple: "Purple",
        .systemIndigo: "Indigo",
        .systemBlue: "Blue",
        .systemCyan: "Cyan",
        .systemGreen: "Green",
        .systemYellow: "Yellow",
        .systemOrange: "Orange",
        .systemRed: "Red"
      ]
      
      let makeColourActions = {(currentColour: UIColor?, callback: @escaping (UIColor) -> Void) -> [UIAction] in
        colours.map({(colour, name) in
          UIAction(
            title: name,
            image: UIImage(systemName: "circle.fill")?.withTintColor(colour).withRenderingMode(.alwaysOriginal),
            state: colour.toHex() == currentColour?.toHex() ? .on : .off) {_ in
              callback(colour)
            }
        })
      }
      
      let actions: [UIMenuElement]
      
      switch self.location {
        case .user, .map:
          actions = makeColourActions(nil) {colour in
            self.coordinatorView.addMarker(coordinate: self.coordinate, colour: colour)
          }
        case .marker(let marker):
          let removePin = UIAction(
            title: "Remove Marker",
            image: UIImage(systemName: "mappin.slash"),
            attributes: .destructive
          ) {[unowned self] _ in
            self.coordinatorView.removeMarker(marker)
            }
          
          let editTitle = UIAction(
            title: marker.title != nil ? "Rename \(marker.title!)" : "Add Title",
            image: UIImage(systemName: "character.cursor.ibeam")
          ) {[unowned self] _ in
            self.coordinatorView.goTo(1, data: marker)
          }
          
          let changeColourChildren = [
            UIAction(title: "Other...", image: UIImage(systemName: "circle.hexagongrid.fill")?.withRenderingMode(.alwaysOriginal)){ _ in
              let colourPicker = UIColourPickerViewController(){[unowned self] colour in self.coordinatorView.changeMarker(marker, colour: colour)}
              colourPicker.supportsAlpha = true
              colourPicker.selectedColor = marker.colour
              
              MapViewController.shared.lifpc.present(colourPicker, animated: true, completion: nil)
            }
          ] + makeColourActions(marker.colour) {[unowned self] colour in self.coordinatorView.changeMarker(marker, colour: colour)}
          
          let colourMenu = UIMenu(title: "Change Colour", image: UIImage(systemName: "circle.fill")?.withTintColor(marker.colour).withRenderingMode(.alwaysOriginal), children: changeColourChildren)
          
          actions = [removePin, colourMenu, editTitle]
      }
 
      completion(actions)
    })
  }

  init(coordinatorView: LocationInfoCoordinatorView){
    self.coordinatorView = coordinatorView
    
    super.init(frame: CGRect())
    
    addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
    mainView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    mainView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    mainView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
    
  func viewWillEnter(data: Any?){
    coordinatorView.panelViewController.panelButtons = [.share, .custom(markerButton), .dismiss]
    
    if(MapViewController.shared.lifpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lifpc.move(to: .tip, animated: true)
    }
    
    coordinatorView.panelViewController.popoverTitle.pasteDelegate = self
    coordinatorView.panelViewController.popoverTitle.isUserInteractionEnabled = true
    coordinatorView.panelViewController.popoverTitle.addGestureRecognizer(labelTap)
    
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    
    userLocationDidUpdate()
    
    update(data: data)
  }
  
  func viewWillExit() {
    coordinatorView.panelViewController.popoverTitle.pasteDelegate = nil
    coordinatorView.panelViewController.popoverTitle.isUserInteractionEnabled = false
    coordinatorView.panelViewController.popoverTitle.removeGestureRecognizer(labelTap)
    
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.remove(delegate: self)
  }
  

  func update(data: Any?){
    if let location = data as? LocationInfoType {
      print("location update", location)
      updateMarkerButton()
      
      switch location {
        case .user:
          metricDisplays = [headingDisplay, elevationDisplay]
          
          userLocationDidUpdate()
        case .marker, .map:
          nonUserLocationDidUpdate()
      }
    }
  }
        
  func updateMarkerButton(){
    markerButton.showsMenuAsPrimaryAction = true
    
    let menuTitle: String
    
    switch location {
      case .user, .map:
        menuTitle = "Add Marker"
        markerButton.setDisplayConfig(.init(icon: .systemName("plus"), colour: MarkerManager.shared.latestColour))
      case .marker(let marker):
        menuTitle = ""
        markerButton.setDisplayConfig(.init(icon: .systemName("screwdriver.fill"), colour: marker.colour))
    }
    
    markerButton.menu = UIMenu(title: menuTitle, children: [defferedMenuElement])
  }
  
  func nonUserLocationDidUpdate() {
    switch location {
      case .marker(let marker) where marker.title != nil: titleContent = .title(marker)
      default:
        switch titleContent {
          case .title, .none: titleContent = .coordinate(.decimal)
          default: titleContent = titleContent!
        }
    }
  
    metricDisplays = [bearingDisplay, distanceDisplay]
    
    var distanceValue = (distanceDisplay.value as! CoordinatePair)
    distanceValue.a = coordinate
    distanceDisplay.value = distanceValue
    
    var bearingValue = (bearingDisplay.value as! CoordinatePair)
    bearingValue.a = coordinate
    bearingDisplay.value = bearingValue
  }
  
 
  func userLocationDidUpdate() {
    guard let userLocation = MapViewController.shared.mapView.userLocation else {
      return
    }
    
    let coordinate = userLocation.coordinate
    let heading = userLocation.heading
    let location = userLocation.location
    
    if case .user = self.location {
      switch titleContent {
        case .title: titleContent = .coordinate(.decimal)
        default: titleContent = titleContent ?? .coordinate(.decimal)
      }
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
  
  func panelButtonTapped(button: PanelButtonType) {
    let panelButton = coordinatorView.panelViewController.getPanelButton(button)
    
    if(button == .share){
      showShareSheet(panelButton)
    }
  }
  
  func userDidPaste(content: String) {
    if let coordinate = CLLocationCoordinate2D(content){
      coordinatorView.update(location: .map(coordinate))
    }
  }
  
  @objc func labelTapped(){
    switch titleContent! {
      case .coordinate(.decimal): titleContent = .coordinate(.sexagesimal)
      case .coordinate(.sexagesimal): titleContent = .coordinate(.gridReference)
      case .coordinate(.gridReference):
        switch location {
          case .marker(let marker) where marker.title != nil: titleContent = .title(marker)
          default: titleContent = .coordinate(.decimal)
        }
      case .title: titleContent = .coordinate(.decimal)
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

enum TitleFormat {
  case title(Marker)
  case coordinate(CoordinateFormat)
}

enum CoordinateFormat {
  case decimal
  case sexagesimal
  case gridReference
}
