import Foundation
import UIKit

import CoreLocation
import MobileCoreServices
import LinkPresentation

import Mapbox

extension LocationInfoPanelViewController {
  func generatePreview(coordinate: CLLocationCoordinate2D, _ callback: @escaping (UIImage) -> ()){
    let options = MGLMapSnapshotOptions(
      styleURL: MapViewController.shared.mapView.styleURL,
      camera: MGLMapCamera(lookingAtCenter: coordinate, altitude: MapViewController.shared.mapView.camera.altitude, pitch: 0, heading: 0),
      size: CGSize(width: 600, height: 600)
    )
    options.zoomLevel = 15

    
    // Create the map snapshot.
    let snapshotter = MGLMapSnapshotter(options: options)
    snapshotter.start {(snapshot, error) in
      if error != nil {
        print("Unable to create a map snapshot.")
      } else if let snapshot = snapshot {
        callback(snapshot.image)
      }
    }
  }
  
  func showShareSheet(_ sender: PanelButton) {
    let coordinate: CLLocationCoordinate2D
    
    switch location {
      case .user:
        coordinate = MapViewController.shared.mapView.userLocation!.coordinate
      case .map(let coord):
        coordinate = coord
    }
    
    generatePreview(coordinate: coordinate){image in
      
      let front = UIImage(named: "mapPin")!.withTintColor(.systemPink)
      let back = UIImage(named: "mapPinBack")!
    
      let mapPin = front.draw(inFrontOf: back).resized(to: front.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)))
      
      let composite = mapPin.draw(inFrontOf: image)

      let activityViewController = UIActivityViewController(
        activityItems: [CoordinateActivityItemProvider(coordinate: coordinate, image: composite), composite],
        applicationActivities: [
          GoogleMapsActivity(coordinate: coordinate),
          GoogleMapsStreetViewActivity(coordinate: coordinate)
        ]
      )
      
      activityViewController.popoverPresentationController?.sourceView = sender
      self.present(activityViewController, animated: true, completion: nil)
    }
  }
}

class CoordinateActivityItemProvider: UIActivityItemProvider {
  let coordinate: CLLocationCoordinate2D
  let image: UIImage?
  
  override var item: Any {
    get {URLInterface.shared.encode(commands: [.go(coordinate)]) as Any}
  }
  
  init(coordinate: CLLocationCoordinate2D, image: UIImage?) {
    self.coordinate = coordinate
    self.image = image
    
    super.init(placeholderItem: "WOW")
  }
  
  override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
    let linkMetaData = LPLinkMetadata()
    
    let itemProvider = NSItemProvider()
    linkMetaData.iconProvider = itemProvider
    linkMetaData.imageProvider = itemProvider

    if(image != nil) {
      itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePNG as String, visibility: .all) {completion in
        completion(self.image!.pngData(), nil)
        
        return nil
      }
    }

    linkMetaData.title = "Shared Location"
    linkMetaData.originalURL = URL(fileURLWithPath: coordinate.format(.decimal(.low)))

    return linkMetaData
}
  
  override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    if(activityType != nil) {
      switch activityType! {
        case .message, .postToFacebook, .postToWeibo, .postToVimeo, .postToFlickr, .postToTwitter, .postToTencentWeibo:
          return "Shared Location from Gaia:\n\n\(coordinate.format(.decimal(.low)))\n\n\(item)"
        case .airDrop:
          return URL(string: "https://maps.apple.com?ll=\(coordinate.latitude),\(coordinate.longitude)")!
        case .copyToPasteboard:
          return coordinate.format(.decimal(.high))
        default:
          return coordinate.format(.decimal(.low))
      }
    }
    
    return coordinate.format(.decimal(.low))
  }
  
  override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType: UIActivity.ActivityType?) -> String {
    return "Shared Location from Gaia: \(coordinate.format(.decimal(.low)))"
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


