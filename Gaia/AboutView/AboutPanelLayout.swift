import Foundation
import UIKit

import FloatingPanel

let aboutPanelLayout = MapViewPanelLayout(
  position: .bottom,
  initialState: .full,
  anchors: [
    .full: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea)
  ]
)
