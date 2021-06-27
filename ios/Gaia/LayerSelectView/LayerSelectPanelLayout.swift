import Foundation
import UIKit

import FloatingPanel

let layerSelectPanelLayout = PanelLayout(
  position: .bottom,
  initialState: .half,
  anchors: [
    .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
    .half: FloatingPanelLayoutAnchor(fractionalInset: 0.6, edge: .bottom, referenceGuide: .safeArea),
    .tip: FloatingPanelLayoutAnchor(absoluteInset: hasHomeButton ? 75 : 60, edge: .bottom, referenceGuide: .safeArea)
  ]
)
