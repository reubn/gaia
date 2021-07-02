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
  
  // https://stackoverflow.com/a/34641936
  func isVisible() -> Bool {
    return UIView.isVisible(view: self, inView: superview)
  }
  
  static func isVisible(view: UIView, inView: UIView?) -> Bool {
    guard let inView = inView else { return true }
    let viewFrame = inView.convert(view.bounds, from: view)
    
    return viewFrame.intersects(inView.bounds) ? isVisible(view: view, inView: inView.superview) : false
  }
}
