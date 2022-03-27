import Foundation
import CoreLocation

// https://stackoverflow.com/a/53195730/12833778

extension CLLocationCoordinate2D {
  init?(sexagesimal string: String) {
    print("sex", string)
    let directionIsPrefix = "NEWS".contains(string.prefix(1))
    let pattern = directionIsPrefix
    ? "([NEWS])\\s?([0-9.-]+)°\\s?([0-9.-]+)['’′‘]\\s?([0-9.-]+\\.?([0-9.-]+)?)[\"”″]"
    : "([0-9.-]+)°\\s?([0-9.-]+)['’′‘]\\s?([0-9.-]+\\.?([0-9.-]+)?)[\"”″]\\s?([NEWS])"
    
    var latlng = [Double]()
    
    do {
      let regex = try NSRegularExpression(pattern: pattern)
      let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
      guard matches.count == 2 else {return nil}
      print("sex m", string)
      for match in matches {
        let m1 = string[Range(match.range(at:1), in: string)!]
        let m2 = string[Range(match.range(at:2), in: string)!]
        let m3 = string[Range(match.range(at:3), in: string)!]
        let lastIndex = directionIsPrefix ? 4 : 5
        let m4 = string[Range(match.range(at:lastIndex), in: string)!]
        let value: Double
        
        if directionIsPrefix {
          let sign = "NE".contains(m1) ? 1.0 : -1.0
          value = sign * (Double(m2)! + Double(m3)!/60.0 + Double(m4)!/3600.0)
        } else {
          let sign = "NE".contains(m4) ? 1.0 : -1.0
          value = sign * (Double(m1)! + Double(m2)!/60.0 + Double(m3)!/3600.0)
        }
        
        latlng.append(value)
      }
    } catch {
      return nil
    }
    
    self.init(latitude: latlng[0], longitude: latlng[1])
  }
}
