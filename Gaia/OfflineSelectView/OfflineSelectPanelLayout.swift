import Foundation
import UIKit

import FloatingPanel

let offlineSelectPanelLayout = MapViewPanelLayout(
  position: .bottom,
  initialState: .full,
  anchors: [
    .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
    .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
  ]
)
