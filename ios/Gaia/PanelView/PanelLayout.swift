import Foundation
import UIKit

import FloatingPanel

class PanelLayout: FloatingPanelLayout {
  var position: FloatingPanelPosition
  var initialState: FloatingPanelState
  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]
  

  init(position: FloatingPanelPosition, initialState: FloatingPanelState, anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]){
    self.position = position
    self.initialState = initialState
    self.anchors = anchors
  }

  func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
    return true
  }

  func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
    return 0
  }
  
  func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
    if UIDevice.current.userInterfaceIdiom == .phone {
      if(UIDevice.current.orientation.isValidInterfaceOrientation ? UIDevice.current.orientation.isPortrait : ((UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows.first?.windowScene?.interfaceOrientation.isPortrait)!) {
        // iPhone Portrait
        return [
          surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
          surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ]
      }
      
      // iPhone Landscape
      return [
        surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      ]
    }
  
    // iPad Portrait + Landscape
    return [
        surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
        surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -20),
    ]
  }
}
