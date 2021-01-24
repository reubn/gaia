import Foundation
import UIKit

import Mapbox

class OfflineSelectZoom: UIView, CoordinatedView, ParentMapViewRegionIsChangingDelegate {
  let coordinatorView: OfflineSelectCoordinatorView

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    super.init(frame: CGRect())
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSZ")
    coordinatorView.mapViewController.osfpc.move(to: .tip, animated: true)
    coordinatorView.panelViewController.title = "Select Zoom"
    coordinatorView.panelViewController.buttons = [.previous, .accept]
    
    coordinatorView.mapViewController.mapView.isScrollEnabled = false
    coordinatorView.mapViewController.mapView.isRotateEnabled = false
    coordinatorView.mapViewController.mapView.isPitchEnabled = false
    coordinatorView.mapViewController.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = true
    coordinatorView.mapViewController.mapView.setVisibleCoordinateBounds(coordinatorView.selectedArea!, animated: true)
    
    coordinatorView.mapViewController.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    
    coordinatorView.selectedZoom = nil
  }
  
  func viewWillExit(){
    print("exit OSZ")
    
    coordinatorView.mapViewController.mapView.isScrollEnabled = true
    coordinatorView.mapViewController.mapView.isRotateEnabled = true
    coordinatorView.mapViewController.mapView.isPitchEnabled = true
    coordinatorView.mapViewController.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = false
    
    coordinatorView.mapViewController.multicastParentMapViewRegionIsChangingDelegate.remove(delegate: self)
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept){
      coordinatorView.selectedZoom = coordinatorView.mapViewController.mapView.zoomLevel.rounded(.up)
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
  
  func parentMapViewRegionIsChanging() {
    coordinatorView.panelViewController.title = "Select Zoom: \(Int(coordinatorView.mapViewController.mapView.zoomLevel.rounded(.up)))"
    
  }
}

