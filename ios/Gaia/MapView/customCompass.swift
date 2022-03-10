// Adapted from https://github.com/mapbox/mapbox-gl-native-ios/blob/main/platform/ios/src/MGLCompassButton.mm

import Foundation
import UIKit
import Mapbox
@_spi(Experimental)import MapboxMaps

fileprivate let directionFormatter: CompassDirectionFormatter = {
  let formatter = CompassDirectionFormatter()
  formatter.style = .short
  return formatter
}()

extension MapViewController {
  fileprivate enum Constants {
    static let localizableTableName = "OrnamentsLocalizable"
    static let compassSize = CGSize(width: 40, height: 40)
    static let animationDuration: TimeInterval = 0.3
  }
  
  fileprivate var containerView: UIImageView {
    mapView.ornaments.compassView.subviews.first(where: {$0 as? UIImageView != nil}) as! UIImageView
  }
  
  func compass(){
    let subView = UIView(frame: mapView.ornaments.compassView.bounds)
    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
    
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
    blur.frame = subView.bounds
    blur.autoresizingMask = subView.autoresizingMask
    blur.isUserInteractionEnabled = false

    subView.insertSubview(blur, at: 0)
    mapView.ornaments.compassView.insertSubview(subView, at: 0)
    
    subView.layer.cornerRadius = Constants.compassSize.height / 2
    subView.layer.masksToBounds = true
    subView.clipsToBounds = true
    
    mapView.ornaments.compassView.layer.shadowColor = UIColor.black.cgColor;
    mapView.ornaments.compassView.layer.shadowOffset = CGSize(width: 0, height: 0);
    mapView.ornaments.compassView.layer.shadowOpacity = 0.25;
    mapView.ornaments.compassView.layer.shadowRadius = 10;
    
    mapView.ornaments.compassView.accessibilityLabel = "Compass"
  }
  
  func updateCompass(dark: Bool = true){
    containerView.image = compassImage(dark: dark)
  }
  
  func compassImage(dark: Bool = true) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(Constants.compassSize, false, UIScreen.main.scale)
    
    //// Color Declarations
    let foregroundColour: UIColor = dark ? .white : .black
    let arrowColour = UIColor(red: 1.000, green: 0.235, blue: 0.196, alpha: 1.000)
  
    //// Bezier Drawing
    let bezierPath = UIBezierPath()
    bezierPath.move(to: CGPoint(x: 19.68, y: 3.85))
    bezierPath.addLine(to: CGPoint(x: 20.43, y: 3.85))
    bezierPath.addLine(to: CGPoint(x: 20.43, y: 7.6))
    bezierPath.addLine(to: CGPoint(x: 19.68, y: 7.6))
    bezierPath.addLine(to: CGPoint(x: 19.68, y: 3.85))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 26.02, y: 4.96))
    bezierPath.addLine(to: CGPoint(x: 26.71, y: 5.25))
    bezierPath.addLine(to: CGPoint(x: 25.24, y: 8.71))
    bezierPath.addLine(to: CGPoint(x: 24.55, y: 8.41))
    bezierPath.addLine(to: CGPoint(x: 26.02, y: 4.96))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 31.42, y: 8.4))
    bezierPath.addLine(to: CGPoint(x: 31.95, y: 8.93))
    bezierPath.addLine(to: CGPoint(x: 29.29, y: 11.58))
    bezierPath.addLine(to: CGPoint(x: 28.77, y: 11.05))
    bezierPath.addLine(to: CGPoint(x: 31.42, y: 8.4))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 35.11, y: 13.67))
    bezierPath.addLine(to: CGPoint(x: 35.39, y: 14.36))
    bezierPath.addLine(to: CGPoint(x: 31.91, y: 15.77))
    bezierPath.addLine(to: CGPoint(x: 31.64, y: 15.07))
    bezierPath.addLine(to: CGPoint(x: 35.11, y: 13.67))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 36.5, y: 19.92))
    bezierPath.addLine(to: CGPoint(x: 36.5, y: 20.66))
    bezierPath.addLine(to: CGPoint(x: 32.75, y: 20.66))
    bezierPath.addLine(to: CGPoint(x: 32.75, y: 19.92))
    bezierPath.addLine(to: CGPoint(x: 36.5, y: 19.92))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 35.39, y: 26.26))
    bezierPath.addLine(to: CGPoint(x: 35.09, y: 26.94))
    bezierPath.addLine(to: CGPoint(x: 31.64, y: 25.48))
    bezierPath.addLine(to: CGPoint(x: 31.93, y: 24.79))
    bezierPath.addLine(to: CGPoint(x: 35.39, y: 26.26))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 31.95, y: 31.65))
    bezierPath.addLine(to: CGPoint(x: 31.42, y: 32.18))
    bezierPath.addLine(to: CGPoint(x: 28.77, y: 29.53))
    bezierPath.addLine(to: CGPoint(x: 29.29, y: 29))
    bezierPath.addLine(to: CGPoint(x: 31.95, y: 31.65))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 26.68, y: 35.35))
    bezierPath.addLine(to: CGPoint(x: 25.99, y: 35.63))
    bezierPath.addLine(to: CGPoint(x: 24.58, y: 32.15))
    bezierPath.addLine(to: CGPoint(x: 25.27, y: 31.87))
    bezierPath.addLine(to: CGPoint(x: 26.68, y: 35.35))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 20.43, y: 36.73))
    bezierPath.addLine(to: CGPoint(x: 19.68, y: 36.73))
    bezierPath.addLine(to: CGPoint(x: 19.68, y: 32.98))
    bezierPath.addLine(to: CGPoint(x: 20.43, y: 32.98))
    bezierPath.addLine(to: CGPoint(x: 20.43, y: 36.73))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 14.09, y: 35.62))
    bezierPath.addLine(to: CGPoint(x: 13.41, y: 35.33))
    bezierPath.addLine(to: CGPoint(x: 14.87, y: 31.88))
    bezierPath.addLine(to: CGPoint(x: 15.56, y: 32.17))
    bezierPath.addLine(to: CGPoint(x: 14.09, y: 35.62))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 8.69, y: 32.18))
    bezierPath.addLine(to: CGPoint(x: 8.17, y: 31.65))
    bezierPath.addLine(to: CGPoint(x: 10.82, y: 29))
    bezierPath.addLine(to: CGPoint(x: 11.35, y: 29.53))
    bezierPath.addLine(to: CGPoint(x: 8.69, y: 32.18))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 5.02, y: 26.94))
    bezierPath.addLine(to: CGPoint(x: 4.73, y: 26.26))
    bezierPath.addLine(to: CGPoint(x: 8.18, y: 24.79))
    bezierPath.addLine(to: CGPoint(x: 8.47, y: 25.48))
    bezierPath.addLine(to: CGPoint(x: 5.02, y: 26.94))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 3.61, y: 20.66))
    bezierPath.addLine(to: CGPoint(x: 3.61, y: 19.92))
    bezierPath.addLine(to: CGPoint(x: 7.36, y: 19.92))
    bezierPath.addLine(to: CGPoint(x: 7.36, y: 20.66))
    bezierPath.addLine(to: CGPoint(x: 3.61, y: 20.66))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 4.73, y: 14.33))
    bezierPath.addLine(to: CGPoint(x: 5.02, y: 13.64))
    bezierPath.addLine(to: CGPoint(x: 8.47, y: 15.11))
    bezierPath.addLine(to: CGPoint(x: 8.18, y: 15.79))
    bezierPath.addLine(to: CGPoint(x: 4.73, y: 14.33))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 8.17, y: 8.93))
    bezierPath.addLine(to: CGPoint(x: 8.69, y: 8.4))
    bezierPath.addLine(to: CGPoint(x: 11.35, y: 11.05))
    bezierPath.addLine(to: CGPoint(x: 10.82, y: 11.58))
    bezierPath.addLine(to: CGPoint(x: 8.17, y: 8.93))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 13.43, y: 5.23))
    bezierPath.addLine(to: CGPoint(x: 14.12, y: 4.96))
    bezierPath.addLine(to: CGPoint(x: 15.53, y: 8.43))
    bezierPath.addLine(to: CGPoint(x: 14.84, y: 8.71))
    bezierPath.addLine(to: CGPoint(x: 13.43, y: 5.23))
    bezierPath.close()
    bezierPath.usesEvenOddFillRule = true
    foregroundColour.setFill()
    bezierPath.fill()
    
    //// Bezier 2 Drawing
    let bezier2Path = UIBezierPath()
    bezier2Path.move(to: CGPoint(x: 20, y: 10))
    bezier2Path.addLine(to: CGPoint(x: 24, y: 18))
    bezier2Path.addLine(to: CGPoint(x: 16, y: 18))
    bezier2Path.addLine(to: CGPoint(x: 20, y: 10))
    bezier2Path.close()
    bezier2Path.usesEvenOddFillRule = true
    arrowColour.setFill()
    bezier2Path.fill()
    
    let northFont = UIFont.systemFont(ofSize: 11, weight: .light)
    let northLocalized = directionFormatter.string(from: 0)
    let north = NSAttributedString(string: northLocalized, attributes:
                                    [
                                      NSAttributedString.Key.font: northFont,
                                      NSAttributedString.Key.foregroundColor: foregroundColour
                                    ])
    let stringRect = CGRect(x: (Constants.compassSize.width - north.size().width) / 2,
                            y: Constants.compassSize.height * 0.435,
                            width: north.size().width,
                            height: north.size().height)
    north.draw(in: stringRect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return image
  }
}
