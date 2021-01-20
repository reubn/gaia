import Foundation
import UIKit
import FloatingPanel

class OfflineSelectPanelLayout: FloatingPanelLayout {
  let position: FloatingPanelPosition = .bottom
  let initialState: FloatingPanelState = .full
  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    return [
      .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
//      .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea)
      .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
    ]
  }

  func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
    return true
  }

  func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
    return 0
  }
}
