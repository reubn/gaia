import Foundation
import UIKit

import CoreLocation
import UniformTypeIdentifiers
import LinkPresentation

import Mapbox

extension LocationInfoPanelViewController {
  func generatePreview(coordinate: CLLocationCoordinate2D, _ callback: @escaping (UIImage?) -> ()){
    if(OfflineManager.shared.offlineMode) {
        return callback(nil)
    }
    
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
        callback(nil)
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
      let composite: UIImage? = image != nil ? {
        let front = UIImage(named: "mapPin")!.withTintColor(.systemPink)
        let back = UIImage(named: "mapPinBack")!
        
        let mapPin = front.draw(inFrontOf: back).resized(to: front.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)))
        
        return mapPin.draw(inFrontOf: image!)
      }() : nil

      let activityViewController = UIActivityViewController(
        activityItems: [
          CoordinateTextActivityItemProvider(coordinate: coordinate, image: composite),
          CoordinateImageActivityItemSource(coordinate: coordinate, image: composite)
        ],
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

class CoordinateTextActivityItemProvider: UIActivityItemProvider {
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
    let linkMetadata = LPLinkMetadata()
    
    let itemProvider = NSItemProvider()
    linkMetadata.iconProvider = itemProvider
    linkMetadata.imageProvider = itemProvider

    if(image != nil) {
      itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) {completion in
        completion(self.image!.pngData(), nil)
        
        return nil
      }
    }

    linkMetadata.title = "Shared Location"
    linkMetadata.originalURL = URL(fileURLWithPath: coordinate.format(.decimal(.low)))

    return linkMetadata
}
  
  override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    let `default` = "Shared Location from Gaia:\n\n\(coordinate.format(.decimal(.low)))\n\n\(item)"
    
    guard let activityType = activityType else {
      return `default`
    }
    
    switch activityType {
      case .airDrop:
        return URL(string: "https://maps.apple.com?q=Shared%20Location&ll=\(coordinate.latitude),\(coordinate.longitude)")
      default:
        return `default`
    }
  }
  
  override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType: UIActivity.ActivityType?) -> String {
    return "Shared Location from Gaia: \(coordinate.format(.decimal(.low)))"
  }
}

class CoordinateImageActivityItemSource: NSObject, UIActivityItemSource {
  let coordinate: CLLocationCoordinate2D
  let image: UIImage?
  
  init(coordinate: CLLocationCoordinate2D, image: UIImage?) {
    self.coordinate = coordinate
    self.image = image
  }
  
  
  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    return image as Any
  }
  
  func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    guard let activityType = activityType else {
      return nil
    }

    switch activityType {
      case .message, .postToFacebook, .postToWeibo, .postToVimeo, .postToFlickr, .postToTwitter, .postToTencentWeibo:
        return image
      default:
        return nil
    }
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
