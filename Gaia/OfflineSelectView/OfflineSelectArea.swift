import Foundation
import UIKit

import Mapbox

class OfflineSelectArea: UIView, CoordinatedView {
  let coordinatorView: OfflineSelectCoordinatorView

  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    super.init(frame: CGRect())
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSA")
    coordinatorView.mapViewController.osfpc.move(to: .tip, animated: true)
    coordinatorView.panelViewController.title = "Select Area"
    coordinatorView.panelViewController.buttons = [.accept, .reject]
  }
  
  func viewWillExit(){
    print("exit OSA")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept){
      coordinatorView.forward()
    } else if(button == .reject){
      coordinatorView.back()
    }
  }
}



//coordinatorView.mapViewController.osfpc.move(to: .full, animated: true)
//coordinatorView.panelViewController.title = "Select Layers"
//coordinatorView.panelViewController.buttons = [.okay]

