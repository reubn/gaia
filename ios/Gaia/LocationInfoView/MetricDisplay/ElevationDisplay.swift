import Foundation
import UIKit
import CoreLocation

class ElevationDisplay: MetricDisplay {
  var mode: Mode = .altitude {
    didSet {
      emoji = emojiLookup[mode]
      updateValue()
    }
  }
  
  let emojiLookup: [Mode: String] = [.altitude: "⛰", .floor: "🏢"]
  
  override init(){
    super.init()
    
    emoji = emojiLookup[mode]
  }
  
  @objc override func tapped() {
    switch mode {
      case .altitude:
        mode = .floor
      case .floor:
        mode = .altitude
    }
  }
  
  override func format() -> (String, String) {
    if(value == nil) {return ("??", "??")}
    
    let value = self.value as! CLLocation
    
    let string: String
    
    switch mode {
      case .altitude:
        string = String(format: "%dm", Int(value.altitude))
      case .floor:
        string = value.floor != nil ? String(format: "%d", Int(value.floor!.level)) : "??"
    }
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum Mode {
    case altitude, floor
  }
}
