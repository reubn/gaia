import Foundation
import UIKit

import Mapbox

class OfflineSelectZoom: UIView, CoordinatedView, ParentMapViewRegionIsChangingDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    super.init(frame: CGRect())
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSZ")
    
    MapViewController.shared.osfpc.move(to: .tip, animated: true)
    coordinatorView.panelViewController.title = "Select Zoom"
    coordinatorView.panelViewController.panelButtons = [.previous, .accept]
    
    MapViewController.shared.mapView.isScrollEnabled = false
    MapViewController.shared.mapView.isRotateEnabled = false
    MapViewController.shared.mapView.isPitchEnabled = false
    MapViewController.shared.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = true
    MapViewController.shared.mapView.setVisibleCoordinateBounds(coordinatorView.selectedArea!, animated: true)
    
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    
    coordinatorView.selectedZoom = nil
  }
  
  func viewWillExit(){
    print("exit OSZ")
    
    MapViewController.shared.mapView.isScrollEnabled = true
    MapViewController.shared.mapView.isRotateEnabled = true
    MapViewController.shared.mapView.isPitchEnabled = true
    MapViewController.shared.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = false
    
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.remove(delegate: self)
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .accept){
      let to = MapViewController.shared.mapView.zoomLevel.rounded(.up)
      coordinatorView.selectedZoom = .init(from: to - 2, to: to)
      
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
  
  func parentMapViewRegionIsChanging() {
    coordinatorView.panelViewController.title = "Select Zoom: \(Int(MapViewController.shared.mapView.zoomLevel.rounded(.up)))"
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

