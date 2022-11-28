import Foundation
import UIKit
import CoreLocation
import Turf

class PathLengthDisplay: MetricDisplay {
  let formatter = NumberFormatter()
  
  var mode: Mode = .metric {
    didSet {
      emoji = emojiLookup[mode]
      updateValue()
    }
  }
  
  let emojiLookup: [Mode: String] = [.metric: "🧵", .imperial: "🧵"]
  
  override init(){
    super.init()
    
    value = [CLLocationCoordinate2D]()
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
    guard let coordinates = self.value as? [CLLocationCoordinate2D], !coordinates.isEmpty else {return ("??", "??")}
    print("measuring", coordinates.count)
    
    let lineString = LineString(coordinates)
    
    let lineLength = lineString.distance() ?? 0
    
    let string: String
    
    switch mode {
      case .metric:
        string = formatter.stringMetric(meters: lineLength)
      case .imperial:
        string = formatter.stringImperial(meters: lineLength)
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
