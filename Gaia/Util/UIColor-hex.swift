import Foundation
import UIKit

extension UIColor {
  // https://omaralbeik.com/blog/uicolor-from-hex
  convenience init?(hex: String) {
    var hexString = hex

    if hexString.hasPrefix("#") { // Remove the '#' prefix if added.
      let start = hexString.index(hexString.startIndex, offsetBy: 1)
      hexString = String(hexString[start...])
    }

    if hexString.lowercased().hasPrefix("0x") { // Remove the '0x' prefix if added.
      let start = hexString.index(hexString.startIndex, offsetBy: 2)
      hexString = String(hexString[start...])
    }

    let r, g, b, a: CGFloat
    let scanner = Scanner(string: hexString)
    var hexNumber: UInt64 = 0
    guard scanner.scanHexInt64(&hexNumber) else { return nil } // Make sure the strinng is a hex code.

    switch hexString.count {
    case 3, 4: // Color is in short hex format
      var updatedHexString = ""
      hexString.forEach { updatedHexString.append(String(repeating: String($0), count: 2)) }
      hexString = updatedHexString
      self.init(hex: hexString)

    case 6: // Color is in hex format without alpha.
      r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
      g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
      b = CGFloat(hexNumber & 0x0000FF) / 255.0
      a = 1.0
      self.init(red: r, green: g, blue: b, alpha: a)

    case 8: // Color is in hex format with alpha.
      r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
      g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
      b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
      a = CGFloat(hexNumber & 0x000000FF) / 255.0
      self.init(red: r, green: g, blue: b, alpha: a)

    default: // Invalid format.
      return nil
    }
  }
  
  // https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
  
  func toHex(alpha: Bool = false) -> String? {
    guard let components = cgColor.components, components.count >= 3 else {
      return nil
    }

    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)

    if components.count >= 4 {
      a = Float(components[3])
    }

    if alpha {
      return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
    } else {
      return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
  }
  
}
