import Foundation
import UIKit

import Mapbox
import FloatingPanel

class AboutPanelViewController: PanelViewController {
  lazy var mainView = AboutView()
  
  init(){
    super.init(title: nil)
    
    self.panelButtons = [.settings, .dismiss]
    generateMenu()
    
    
    view.addSubview(mainView)
    
    mainView.translatesAutoresizingMaskIntoConstraints = false
    mainView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
    mainView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
    mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  func generateMenu(){
    let newButton = getPanelButton(.settings)
    newButton.menu = UIMenu(title: "Settings", children: [
      UIAction(title: "Show Disabled Layers", image: UIImage(systemName: "square.slash.fill"), setting: SettingsManager.shared.showDisabledLayers, update: generateMenu),
      UIAction(title: "Quick Layer Select", image: UIImage(systemName: "cursorarrow.rays"), setting: SettingsManager.shared.quickLayerSelect, update: generateMenu),
    ])
    newButton.adjustsImageWhenHighlighted = false
    newButton.showsMenuAsPrimaryAction = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
