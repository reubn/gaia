import Foundation
import UIKit

import FloatingPanel

let locationInfoPanelLayout = PanelLayout(
  position: .bottom,
  initialState: .tip,
  anchors: [
    .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
    .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
    .tip: FloatingPanelLayoutAnchor(absoluteInset: 75, edge: .bottom, referenceGuide: .safeArea)
  ]
)
