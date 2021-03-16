import Foundation
import UIKit

import CoreLocation
import MobileCoreServices
import LinkPresentation

class CoordinateActivityItemProvider: UIActivityItemProvider {
  let coordinate: CLLocationCoordinate2D
  
  override var item: Any {
    get {URLInterface.shared.encode(command: .go(coordinate))}
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


