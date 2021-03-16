import Foundation
import UIKit

import Mapbox
import FloatingPanel

class AboutPanelViewController: MapViewPanelViewController {
  lazy var mainView = AboutView()
  
  init(){
    
    super.init(title: nil)
    
    self.panelButtons = [.dismiss]
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
