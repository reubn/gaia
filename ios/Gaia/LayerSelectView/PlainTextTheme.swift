import Foundation
import UIKit
import Runestone

enum HighlightName: String {
  case comment
  case function
  case keyword
  case number
  case `operator`
  case property
  case punctuation
  case string
  case variableBuiltin = "variable.builtin"
  
  init?(_ rawHighlightName: String) {
    var comps = rawHighlightName.split(separator: ".")
    while !comps.isEmpty {
      let candidateRawHighlightName = comps.joined(separator: ".")
      if let highlightName = Self(rawValue: candidateRawHighlightName) {
        self = highlightName
        return
      }
      comps.removeLast()
    }

    return nil
  }
}

protocol EditorTheme: Runestone.Theme {
  var backgroundColor: UIColor { get }
  var userInterfaceStyle: UIUserInterfaceStyle { get }
}

final class PlainTextTheme: EditorTheme {
  let backgroundColor: UIColor = .white
  let userInterfaceStyle: UIUserInterfaceStyle = .light
  
  let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .medium)
  let textColor: UIColor = .darkGray
  
  let gutterBackgroundColor: UIColor = .white
  let gutterHairlineColor: UIColor = .white
  
  let lineNumberColor: UIColor = .darkGray.withAlphaComponent(0.5)
  let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
  
  let selectedLineBackgroundColor: UIColor = .darkGray.withAlphaComponent(0.07)
  let selectedLinesLineNumberColor: UIColor = .darkGray
  let selectedLinesGutterBackgroundColor: UIColor = .darkGray.withAlphaComponent(0.07)
  
  let invisibleCharactersColor: UIColor = .darkGray.withAlphaComponent(0.5)
  
  let pageGuideHairlineColor: UIColor = .darkGray.withAlphaComponent(0.1)
  let pageGuideBackgroundColor: UIColor = .darkGray.withAlphaComponent(0.06)
  
  let markedTextBackgroundColor: UIColor = .darkGray.withAlphaComponent(0.1)
  let markedTextBackgroundCornerRadius: CGFloat = 4
  
  func textColor(for rawHighlightName: String) -> UIColor? {
    return nil
  }
  
  func fontTraits(for rawHighlightName: String) -> FontTraits {
    if let highlightName = HighlightName(rawHighlightName), highlightName == .keyword {
      return .bold
    } else {
      return []
    }
  }
  
  static let shared: PlainTextTheme = PlainTextTheme()
}
