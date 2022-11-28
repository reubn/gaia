import Foundation
import UIKit
import CoreLocation

class DistanceDisplay: MetricDisplay {
  let formatter = NumberFormatter()

  var mode: Mode = .metric {
    didSet {
      emoji = emojiLookup[mode]
      updateValue()
    }
  }
  
  let emojiLookup: [Mode: String] = [.metric: "📏", .imperial: "🗿"]
  
  override init(){
    super.init()
    
    value = CoordinatePair()
    emoji = emojiLookup[mode]
    
    formatter.usesSignificantDigits = true
    formatter.maximumSignificantDigits = 3
  }
  
  @objc override func tapped() {
    switch mode {
      case .metric:
        mode = .imperial
      case .imperial:
        mode = .metric
    }
  }
  
  override func format() -> (String, String) {
    if(value == nil) {return ("??", "??")}
    let value = self.value as! CoordinatePair
    
    if(!value.full) {return ("??", "??")}
    
    let distance = value.a!.distance(to: value.b!)
    
    let string: String
    
    switch mode {
      case .metric:
        string = formatter.stringMetric(meters: distance)
      case .imperial:
        string = formatter.stringImperial(meters: distance)
    }
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum Mode {
    case metric, imperial
  }
}
