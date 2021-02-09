import Foundation
import UIKit

extension UIColor {
  static func randomSystemColor() -> UIColor {
    ([
      .systemRed,
      .systemOrange,
      .systemYellow,
      .systemGreen,
      .systemTeal,
      .systemBlue,
      .systemIndigo,
      .systemPurple,
      .systemPink
    ] as [UIColor]).randomElement()!
  }
}
