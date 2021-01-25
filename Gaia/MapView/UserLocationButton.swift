import Foundation
import UIKit
import Mapbox

class UserLocationButton: MapButton {
  let iconSize: CGFloat = 18
  
  var arrow: CAShapeLayer?
  var mode: MGLUserTrackingMode = .none
 
  init(initialMode: MGLUserTrackingMode) {
    super.init()
    
    let arrow = CAShapeLayer()
    arrow.path = arrowPath()
    arrow.lineWidth = 1.5
    arrow.lineJoin = CAShapeLayerLineJoin.round
    arrow.bounds = CGRect(x: 0, y: 0, width: buttonSize / 2, height: buttonSize / 2)
    arrow.position = CGPoint(x: buttonSize / 2, y: buttonSize / 2)
    arrow.drawsAsynchronously = true
     
    self.arrow = arrow

    updateArrowForTrackingMode(mode: initialMode)
    
    layer.addSublayer(self.arrow!)
  }

  private func arrowPath() -> CGPath {
    let bezierPath = UIBezierPath()
    
    bezierPath.move(to: CGPoint(x: iconSize * 0.5, y: 0))
    bezierPath.addLine(to: CGPoint(x: iconSize * 0.1, y: iconSize))
    bezierPath.addLine(to: CGPoint(x: iconSize * 0.5, y: iconSize * 0.65))
    bezierPath.addLine(to: CGPoint(x: iconSize * 0.9, y: iconSize))
    bezierPath.addLine(to: CGPoint(x: iconSize * 0.5, y: 0))
    bezierPath.close()
     
    return bezierPath.cgPath
  }
 
  func updateArrowForTrackingMode(mode: MGLUserTrackingMode) {
    self.mode = mode
    let rotatedArrow = CGFloat(0.85)
     
    switch mode {
      case .none:
        updateArrow(fillColor: UIColor.clear, strokeColor: tintColor, rotation: rotatedArrow)
      case .follow:
        updateArrow(fillColor: tintColor, strokeColor: tintColor, rotation: rotatedArrow)
      case .followWithHeading:
        updateArrow(fillColor: tintColor, strokeColor: tintColor, rotation: 0)
      case .followWithCourse:
        updateArrow(fillColor: UIColor.systemPink, strokeColor: UIColor.systemPurple, rotation: 0)
      @unknown default:
        fatalError("Unknown user tracking mode")
    }
  }
 
  func updateArrow(fillColor: UIColor, strokeColor: UIColor, rotation: CGFloat) {
    guard let arrow = arrow else { return }
    
    arrow.fillColor = fillColor.cgColor
    arrow.strokeColor = strokeColor.cgColor
    arrow.setAffineTransform(CGAffineTransform.identity.rotated(by: rotation))
     
    if rotation > 0 {
      arrow.position = CGPoint(x: (buttonSize - iconSize) - 3, y: (buttonSize - iconSize) - 2)
    } else {
      arrow.position = CGPoint(x: (buttonSize - iconSize) - 2, y: (buttonSize - iconSize) - 1)
    }
     
    layoutIfNeeded()
  }
    
  override func tintColorDidChange(){
    updateArrowForTrackingMode(mode: mode)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
