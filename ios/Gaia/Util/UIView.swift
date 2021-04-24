import Foundation
import UIKit

extension UIView {
  static func animate(withDuration: TimeInterval, withEase: CAMediaTimingFunction, animations: @escaping () -> ()){
    CATransaction.begin()
    CATransaction.setAnimationTimingFunction(withEase)
    
    UIView.animate(withDuration: withDuration, animations: animations)

    CATransaction.commit()
  }
  
  static func animate(
    withDuration: TimeInterval,
    withCubicBezier: [Float],
    animations: @escaping () -> ()
  ){
    UIView.animate(
      withDuration: withDuration,
      withEase: CAMediaTimingFunction(controlPoints: withCubicBezier[0], withCubicBezier[1], withCubicBezier[2], withCubicBezier[3]),
      animations: animations
    )
  }
}
