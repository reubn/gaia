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
        string = formatMetric(meters: distance)
      case .imperial:
        string = formatImperial(meters: distance)
    }
    
    return (string, string)
  }
  
  func formatMetric(meters: Double) -> String {
    let km = meters >= 1000
    
    let value = km ? (meters / 1000) : meters
    let suffix = km ? "km" : "m"
    
    let string = formatter.string(from: NSNumber(value: value)) ?? "??"
    
    return string + suffix
  }
  
  func formatImperial(meters: Double) -> String {
    let yards = meters * 1.0936133
    
    let miles = yards >= 500
    
    let value = miles ? (yards / 1760) : yards
    let suffix = miles ? "mi" : "yd"
    
    let string = formatter.string(from: NSNumber(value: value)) ?? "??"
    
    return string + suffix
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  enum Mode {
    case metric, imperial
  }
}

struct CoordinatePair {
  var a: CLLocationCoordinate2D? = nil
  var b: CLLocationCoordinate2D? = nil
  
  var full: Bool {
    get {a != nil && b != nil}
  }
}



