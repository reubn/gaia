import Foundation
import UIKit
import CoreLocation

class BearingDisplay: MetricDisplay {
  override init(){
    super.init()
    
    value = CoordinatePair()
    emoji = "🧭"
  }
  
  @objc override func tapped() {}
  
  override func format() -> (String, String) {
    if(value == nil) {return ("???°", "???°")}
    let value = self.value as! CoordinatePair
    
    if(!value.full) {return ("???°", "???°")}
    
    let bearing = Int(value.a!.bearing(to: value.b!))
    
    let string = String(format: "%03d°%@", bearing, cardialDirection(bearing))
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
