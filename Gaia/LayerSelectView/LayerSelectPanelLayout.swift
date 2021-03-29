import Foundation
import UIKit

import FloatingPanel

let layerSelectPanelLayout = MapViewPanelLayout(
  position: .bottom,
  initialState: .half,
  anchors: [
    .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
    .half: FloatingPanelLayoutAnchor(fractionalInset: 0.6, edge: .bottom, referenceGuide: .safeArea)
  ]
)
