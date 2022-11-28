import Foundation
import UIKit
import CoreLocation
import Turf

class PathDistanceAlongDisplay: MetricDisplay {
  let formatter = NumberFormatter()
  let percentFormatter = NumberFormatter()
  
  var mode: Mode = .distanceFromStart {
    didSet {
      emoji = emojiLookup[mode]
      updateValue()
    }
  }
  
  let emojiLookup: [Mode: String] = [.distanceFromStart: "➡️", .distanceToEnd: "🏁", .percentage: "💯"]
  
  override init(){
    super.init()
    
    value = CoordinateArrayWithCoordinate()
    emoji = emojiLookup[mode]
    
    formatter.usesSignificantDigits = true
    formatter.maximumSignificantDigits = 3
    
    percentFormatter.usesSignificantDigits = true
    percentFormatter.maximumSignificantDigits = 2
    percentFormatter.numberStyle = NumberFormatter.Style.percent
    
  }
  
  @objc override func tapped() {
    switch mode {
      case .distanceFromStart:
        mode = .distanceToEnd
      case .distanceToEnd:
        mode = .percentage
      case .percentage:
        mode = .distanceFromStart
    }
  }
  
  override func format() -> (String, String) {
    guard let value = self.value as? CoordinateArrayWithCoordinate, value.full else {return ("??", "??")}

    let lineString = LineString(value.coordinateArray)
    
    guard let lineLength = lineString.distance(),
          let closestPointOnLine = lineString.closestCoordinate(to: value.coordinate!),
//            closestPointOnLine.coordinate.distance(to: value.coordinate!) <= 100,
          let distanceFromStart = lineString.distance(to: closestPointOnLine.coordinate)
          else {return ("??", "??")}
    
//    print("lineLength", lineLength)
//    print("distanceFromLine", closestPointOnLine.coordinate.distance(to: value.coordinate!))
//    print("distanceFromStart", distanceFromStart)
//    print("distanceToEnd", lineLength - distanceFromStart, lineString.distance(from: closestPointOnLine.coordinate) ?? "")
    
    let string: String
    switch mode {
      case .distanceFromStart:
        string = formatter.stringMetric(meters: distanceFromStart)
      case .distanceToEnd:
        string = formatter.stringMetric(meters: lineLength - distanceFromStart)
      case .percentage:
        string = percentFormatter.string(for: distanceFromStart / lineLength) ?? "??"
    }
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum Mode {
    case distanceFromStart, distanceToEnd, percentage
  }
}
