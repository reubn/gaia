// Adapted from https://github.com/mapbox/mapbox-gl-native-ios/blob/main/platform/ios/src/MGLCompassButton.mm

import Foundation
import UIKit
import Mapbox

extension MapViewController {
  func compass(){
//    let subView = UIView(frame: mapView.compassView.bounds)
//    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
//    
//    let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
//    blur.frame = subView.bounds
//    blur.autoresizingMask = subView.autoresizingMask
//    blur.isUserInteractionEnabled = false
//
//    subView.insertSubview(blur, at: 0)
//    mapView.compassView.insertSubview(subView, at: 0)
//    
//    subView.layer.cornerRadius = subView.layer.frame.height / 2
//    subView.layer.masksToBounds = true
//    subView.clipsToBounds = true
//    
//    mapView.compassView.layer.shadowColor = UIColor.black.cgColor;
//    mapView.compassView.layer.shadowOffset = CGSize(width: 0, height: 0);
//    mapView.compassView.layer.shadowOpacity = 0.25;
//    mapView.compassView.layer.shadowRadius = 10;
//    
//    mapView.compassView.accessibilityLabel = "Compass"
  }
  
  func compassImage(dark: Bool = true) -> UIImage? {
    let scaleImage = UIImage(named: dark ? "compassDark" : "compassLight")!

    UIGraphicsBeginImageContextWithOptions(scaleImage.size, false, UIScreen.main.scale)

    scaleImage.draw(in: CGRect(origin: .zero, size: scaleImage.size))
    
    let north = NSAttributedString(
      string: Bundle.init(for: MGLCompassButton.self).localizedString(forKey: "COMPASS_NORTH", value: "N", table: nil),
      attributes: [
        .font: UIFont.systemFont(ofSize: 11, weight: .light),
        .foregroundColor: dark ? UIColor.white : UIColor.black
      ]
    )
    
    let stringRect = CGRect(
      x: (scaleImage.size.width - north.size().width) / 2,
      y: scaleImage.size.height * 0.435,
      width: north.size().width,
      height: north.size().height
    )
    north.draw(in: stringRect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  }
}
