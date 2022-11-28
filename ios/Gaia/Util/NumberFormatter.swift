import Foundation

extension NumberFormatter {
  func stringMetric(meters: Double) -> String {
    let km = meters >= 1000
    
    let value = km ? (meters / 1000) : meters
    let suffix = km ? "km" : "m"
    
    let string = self.string(from: NSNumber(value: value)) ?? "??"
    
    return string + suffix
  }
  
  func stringImperial(meters: Double) -> String {
    let yards = meters * 1.0936133
    
    let miles = yards >= 500
    
    let value = miles ? (yards / 1760) : yards
    let suffix = miles ? "mi" : "yd"
    
    let string = self.string(from: NSNumber(value: value)) ?? "??"
    
    return string + suffix
  }
}
