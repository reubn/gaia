import Foundation
import UIKit

import Mapbox

class OfflineSelectZoom: UIView, CoordinatedView, ParentMapViewRegionIsChangingDelegate, OfflineModeDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
  
  var selectionMode: ToOrFrom {
    didSet {
      switch selectionMode {
        case .to:
          if let to = selectedTo {
            MapViewController.shared.mapView.setZoomLevel(to, animated: true)
          } else if let from = selectedFrom {
            MapViewController.shared.mapView.setZoomLevel(from + 2, animated: true)
          }
          selectedTo = nil
          coordinatorView.panelViewController.panelButtons = [.previous, .accept]
        case .from:
          if let from = selectedFrom {
            MapViewController.shared.mapView.setZoomLevel(from, animated: true)
          } else if let to = selectedTo {
            MapViewController.shared.mapView.setZoomLevel(to - 2, animated: true)
          }
          selectedFrom = nil
          coordinatorView.panelViewController.panelButtons = [.previous, .next]
      }
      
      parentMapViewRegionIsChanging()
    }
  }
  var selectedFrom: Double?
  var selectedTo: Double?

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    
    self.selectionMode = .from
    self.selectedFrom = nil
    self.selectedTo = nil
    
    super.init(frame: CGRect())
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSZ")
    
    MapViewController.shared.osfpc.move(to: .tip, animated: true)
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    MapViewController.shared.mapView.isScrollEnabled = false
    MapViewController.shared.mapView.isRotateEnabled = false
    MapViewController.shared.mapView.isPitchEnabled = false
    MapViewController.shared.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = true
    MapViewController.shared.mapView.setVisibleCoordinateBounds(coordinatorView.selectedArea!, animated: true)
    
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    offlineModeDidChange(offline: OfflineManager.shared.offlineMode)
    
    coordinatorView.selectedZoom = nil
    
    selectionMode = .from
  }
  
  func update(data: Any?) {}
  
  func viewWillExit(){
    print("exit OSZ")
    
    MapViewController.shared.mapView.isScrollEnabled = true
    MapViewController.shared.mapView.isRotateEnabled = true
    MapViewController.shared.mapView.isPitchEnabled = true
    MapViewController.shared.mapView.anchorRotateOrZoomGesturesToCenterCoordinate = false
    
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.remove(delegate: self)
  }

  func panelButtonTapped(button: PanelButtonType){
    if(button == .next){
      if selectionMode == .from {
        selectedFrom = MapViewController.shared.mapView.zoomLevel.rounded(.down)
        selectionMode = .to
      }
    } else if(button == .previous){
      switch self.selectionMode {
        case .from: coordinatorView.back()
        case .to: selectionMode = .from
      }
    } else if(button == .accept) {
      if selectionMode == .to {
        selectedTo = MapViewController.shared.mapView.zoomLevel.rounded(.up)
      }
      
      if let from = selectedFrom,
         let to = selectedTo {
        coordinatorView.selectedZoom = .init(from: from, to: to)
        
        coordinatorView.forward()
      }
    }
  }
  
  func parentMapViewRegionIsChanging() {
    switch selectionMode {
      case .from: coordinatorView.panelViewController.title = "Select Min Zoom: \(Int(MapViewController.shared.mapView.zoomLevel.rounded(.down)))"
      case .to: coordinatorView.panelViewController.title = "Select Max Zoom: \(Int(MapViewController.shared.mapView.zoomLevel.rounded(.up)))"
    }
  }
  
  func offlineModeDidChange(offline: Bool) {
    let acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)
    acceptButton.isEnabled = !offline
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

enum ToOrFrom {
  case to
  case from
}
