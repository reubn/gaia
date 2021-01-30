import Foundation
import UIKit
import CoreLocation

class HeadingDisplay: MetricDisplay {
  var mode: Mode = .magnetic {
    didSet {
      emoji = emojiLookup[mode]
      updateValue()
    }
  }
  
  let emojiLookup: [Mode: String] = [.true: "🐻‍❄️", .magnetic: "🧭"]
  
  override init(){
    super.init()
    
    emoji = emojiLookup[mode]
  }
  
  @objc override func tapped() {
    switch mode {
      case .true:
        mode = .magnetic
      case .magnetic:
        mode = .true
    }
  }
  
  override func format() -> (String, String) {
    if(value == nil) {return ("", "")}
    
    let value = self.value as! CLHeading
    
    let heading: Int
    
    switch mode {
      case .true:
        heading = Int(value.trueHeading)
      case .magnetic:
        heading = Int(value.magneticHeading)
    }
    
    let string = String(format: "%03d°%@", heading, cardialDirection(heading))
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum Mode {
    case `true`, magnetic
  }
}

let cardinalDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
let majorDivision = 360 / Double(cardinalDirections.count - 1)
let minorDivision = majorDivision / 2

let cardialDirection = {(heading: Int) -> String in
  cardinalDirections[Int(floor((Double(heading) + minorDivision) / majorDivision))]
}
