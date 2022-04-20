import Foundation
import UIKit

import Mapbox

class OfflineSelectArea: UIView, CoordinatedView {
  unowned let coordinatorView: OfflineSelectCoordinatorView

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    super.init(frame: CGRect())
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSA")
    MapViewController.shared.osfpc.move(to: .tip, animated: true)
    coordinatorView.panelViewController.title = "Select Area"
    coordinatorView.panelViewController.panelButtons = [.previous, .next]
    
    coordinatorView.selectedArea = nil
  }
  
  func update(data: Any?) {}
  
  func viewWillExit(){
    print("exit OSA")
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .next){
      coordinatorView.selectedArea = MapViewController.shared.mapView.visibleCoordinateBounds
      coordinatorView.forward()
    } else if(button == .previous){
      coordinatorView.back()
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}



//MapViewController.shared.osfpc.move(to: .full, animated: true)
//coordinatorView.panelViewController.title = "Select Layers"
//coordinatorView.panelViewController.buttons = [.next]

