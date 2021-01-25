import Foundation
import UIKit

import FloatingPanel

class LayerSelectPanelLayout: FloatingPanelLayout {
  let position: FloatingPanelPosition = .bottom
  let initialState: FloatingPanelState = .half
  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    return [
      .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
      .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea)
    ]
  }

  func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
    return true
  }

  func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
    return 0
  }
}
