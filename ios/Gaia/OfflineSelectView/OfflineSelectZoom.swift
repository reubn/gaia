import Foundation
import UIKit

import Mapbox
@_spi(Experimental)import MapboxMaps

class OfflineSelectZoom: UIView, CoordinatedView, ParentMapViewRegionIsChangingDelegate, OfflineModeDelegate {
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
    
    MapViewController.shared.mapView.gestures.options.panEnabled = false
    MapViewController.shared.mapView.gestures.options.pinchRotateEnabled = false
    MapViewController.shared.mapView.gestures.options.pinchPanEnabled = false
    MapViewController.shared.mapView.gestures.options.pitchEnabled = false
    MapViewController.shared.mapView.gestures.options.focalPoint = CGPoint(x: MapViewController.shared.mapView.bounds.width * 0.5, y: MapViewController.shared.mapView.bounds.height * 0.5)

    try? MapViewController.shared.mapView.mapboxMap.setCameraBounds(with: CameraBoundsOptions(bounds: coordinatorView.selectedArea!.toCoordinateBounds()))
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    offlineModeDidChange(offline: OfflineManager.shared.offlineMode)
    
    coordinatorView.selectedZoom = nil
  }
  
  func viewWillExit(){
    print("exit OSZ")

    MapViewController.shared.mapView.resetGestures()
    
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.remove(delegate: self)
  }
  
  func panelButtonTapped(button: PanelButtonType){
//    if(button == .accept){
//      let to = MapViewController.shared.mapView.cameraState.zoom.rounded(.up)
//      coordinatorView.selectedZoom = .init(from: to - 2, to: to)
//
//      coordinatorView.forward()
//    } else if(button == .previous){
//      coordinatorView.back()
//    }
  }
  
  func parentMapViewRegionIsChanging() {
    coordinatorView.panelViewController.title = "Select Zoom: \(Int(MapViewController.shared.mapView.mapboxMap.cameraState.zoom.rounded(.up)))"
  }
  
  func offlineModeDidChange(offline: Bool) {
    let acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)
    acceptButton.isEnabled = !offline
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

