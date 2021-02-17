import Foundation
import UIKit
import MobileCoreServices
import LinkPresentation

import Mapbox
import FloatingPanel

class LocationInfoPanelViewController: MapViewPanelViewController, UserLocationDidUpdateDelegate {
  let mapViewController: MapViewController
  
  var location: LocationInfoType

  lazy var mapSource: MGLSource = mapViewController.mapView.style?.source(withIdentifier: "location") ?? {
    let source = MGLShapeSource(identifier: "location", features: [], options: nil)
    
    mapViewController.mapView.style?.addSource(source)
    
    return source
  }()
    
  lazy var mapLayer: MGLStyleLayer = mapViewController.mapView.style?.layer(withIdentifier: "location") ?? {
    let layer =  MGLCircleStyleLayer(identifier: "location", source: mapSource)
    layer.circleColor = NSExpression(forConstantValue: UIColor.systemOrange)
    
    mapViewController.mapView.style?.addLayer(layer)
    
    return layer
  }()
  
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
  
  lazy var metricDisplays = [headingDisplay, elevationDisplay]
  
  init(mapViewController: MapViewController, location: LocationInfoType){
    self.mapViewController = mapViewController
    self.location = location
    
    super.init(title: "")
    self.popoverTitle.isSelectable = true
    
    self.panelButtons = [.share, .star, .dismiss]
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    update(location: location)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    removePointsFromMap()
  }
  
  func update(location: LocationInfoType){
    self.location = location
    
    switch location {
      case .user:
        mapViewController.multicastUserLocationDidUpdateDelegate.add(delegate: self)
        userLocationDidUpdate()
        
        for display in metricDisplays {
          display.isHidden = false
        }
      case .map(let coordinate):
        mapViewController.multicastUserLocationDidUpdateDelegate.remove(delegate: self)
        setCoordinateTitle(coordinate: coordinate)
        displayPointOnMap(coordinate: coordinate)
        for display in metricDisplays {
          display.isHidden = true
        }
    }
  }
  
  func displayPointOnMap(coordinate: CLLocationCoordinate2D){
    let point = MGLPointFeature()
    point.coordinate = coordinate
 
    (mapSource as! MGLShapeSource).shape = point
    _ = mapLayer
  }
  
  func removePointsFromMap(){
    mapViewController.mapView.style?.removeSource(mapSource)
    mapViewController.mapView.style?.removeLayer(mapLayer)
  }

  func setCoordinateTitle(coordinate: CLLocationCoordinate2D){
    self.popoverTitle.text = coordinate.format(toAccuracy: .low)
    self.popoverTitle.textToSelect = coordinate.format(toAccuracy: .high)
  }
  
  func userLocationDidUpdate() {
    if(mapViewController.mapView.userLocation == nil) {return}
    
    let coordinate = mapViewController.mapView.userLocation!.coordinate
    let heading = mapViewController.mapView.userLocation!.heading
    let location = mapViewController.mapView.userLocation!.location
    
    setCoordinateTitle(coordinate: coordinate)
    
    if(heading != nil) {
      self.headingDisplay.value = heading!
    }
    
    if(location != nil) {
      self.elevationDisplay.value = location!
    }
  }
  
  override func panelButtonTapped(button: PanelButton) {
    let panelButton = getPanelButton(button)
    
    if(button == .dismiss){
      dismiss(animated: true, completion: nil)
    } else if(button == .share){
      showShareSheet(panelButton)
    }
  }
  
  func showShareSheet(_ sender: PanelActionButton) {
    let coordinate: CLLocationCoordinate2D
    
    switch location {
      case .user:
        coordinate = mapViewController.mapView.userLocation!.coordinate
      case .map(let coord):
        coordinate = coord
    }
    let activityViewController = UIActivityViewController(
      activityItems: [CoordinateActivityItemProvider(coordinate: coordinate)],
      applicationActivities: [
        GoogleMapsActivity(coordinate: coordinate),
        GoogleMapsStreetViewActivity(coordinate: coordinate)
      ]
    )
    activityViewController.popoverPresentationController?.sourceView = sender

    present(activityViewController, animated: true, completion: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


enum LocationInfoType {
  case user
  case map(CLLocationCoordinate2D)
//  case favourite
}


class CoordinateActivityItemProvider: UIActivityItemProvider {
  let coordinate: CLLocationCoordinate2D
  
  override var item: Any {
    get {URL(string: "http://google.com/maps/place/\(coordinate.latitude),\(coordinate.longitude)")!}
  }
  
  init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
    
    super.init(placeholderItem: "WOW")
  }
  
  override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
    
    let linkMetaData = LPLinkMetadata()

//    linkMetaData.iconProvider = UIImage(systemName: "battery.100.bolt")!

    linkMetaData.title = "Shared Location"

    linkMetaData.originalURL = URL(fileURLWithPath: coordinate.format(toAccuracy: .low))

    return linkMetaData
}
  
  override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    if(activityType != nil) {
      switch activityType! {
        case .message, .postToFacebook, .postToWeibo, .postToVimeo, .postToFlickr, .postToTwitter, .postToTencentWeibo:
          return "Shared Location from Gaia:\n\(coordinate.format(toAccuracy: .low))\n\(item)"
        case .airDrop:
          return URL(string: "https://maps.apple.com?ll=\(coordinate.latitude),\(coordinate.longitude)")!
        case .copyToPasteboard:
          return coordinate.format(toAccuracy: .high)
        default:
          return coordinate.format(toAccuracy: .low)
      }
    }
    
    return coordinate.format(toAccuracy: .low)
  }
  
  override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType: UIActivity.ActivityType?) -> String {
    return "Shared Location from Gaia: \(coordinate.format(toAccuracy: .low))"
  }
}


class GoogleMapsActivity: UIActivity {
  let url: URL
  
  init(coordinate: CLLocationCoordinate2D) {
    self.url = URL(string: "comgooglemaps://?q=\(coordinate.latitude),\(coordinate.longitude)")!
    
    super.init()
  }

  override var activityImage: UIImage? {
    return UIImage(systemName: "map")!
  }

  override var activityTitle: String? {
    return "Open in Google Maps"
  }

  override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    return true
  }

  override func perform() {
    UIApplication.shared.open(url)

    activityDidFinish(true)
  }
}

class GoogleMapsStreetViewActivity: UIActivity {
  let url: URL
  
  init(coordinate: CLLocationCoordinate2D) {
    self.url = URL(string: "comgooglemaps://?mapmode=streetview&center=\(coordinate.latitude),\(coordinate.longitude)&q=\(coordinate.latitude),\(coordinate.longitude)")!
    
    super.init()
  }

  override var activityImage: UIImage? {
    return UIImage(systemName: "binoculars")!
  }

  override var activityTitle: String? {
    return "Open in StreetView"
  }

  override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    return true
  }

  override func perform() {
    UIApplication.shared.open(url)

    activityDidFinish(true)
  }
}


