import Foundation
import UIKit

import Mapbox
import FloatingPanel

class AboutPanelViewController: PanelViewController, SettingsManagerDelegate {
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
    
    SettingsManager.shared.multicastSettingManagerDelegate.add(delegate: self)
  }
  
  func settingsDidChange() {
    print("abp sdc")
    generateMenu()
  }
  
  func generateMenu(){
    let newButton = getPanelButton(.settings)
    newButton.menu = UIMenu(title: "Settings", children: [
      UIMenu(title: "Menu Position", image: UIImage(systemName: SettingsManager.shared.rightHandedMenu.value ? "dpad.right.fill" : "dpad.left.fill"), children: [
        UIAction(title: "Top Right", image: UIImage(systemName: "dpad.right.fill"), state: SettingsManager.shared.rightHandedMenu.value){_ in
          SettingsManager.shared.rightHandedMenu.set(true)
          SettingsManager.shared.settingsDidChange()
        },
        UIAction(title: "Top Left", image: UIImage(systemName: "dpad.left.fill"), state: !SettingsManager.shared.rightHandedMenu.value){_ in
          SettingsManager.shared.rightHandedMenu.set(false)
          SettingsManager.shared.settingsDidChange()
        }
      ]),
      UIAction(title: "Show Disabled Layers", image: UIImage(systemName: "square.slash.fill"), setting: SettingsManager.shared.showDisabledLayers, update: SettingsManager.shared.settingsDidChange),
      UIMenu(title: "Screen Brightness", image: UIImage(systemName: "sun.max.fill"), children: [
        UIAction(title: "\(SettingsManager.shared.autoAdjustment.value ? "Disable" : "Enable") Auto Adjustment", image: UIImage(systemName: SettingsManager.shared.autoAdjustment.value ? "sun.max.fill" : "sun.min")){_ in
          SettingsManager.shared.autoAdjustment.toggle()
          
          if !SettingsManager.shared.autoAdjustment.value {
            // being disabled
            SettingsManager.shared.autoAdjustmentLowPoint.reset()

            HUDManager.shared.displayMessage(message: .autoAdjustmentDisabled)
          } else {
            // being enabled
            HUDManager.shared.displayMessage(message: .autoAdjustmentEnabled)
          }
    
          SettingsManager.shared.settingsDidChange()
        },
        UIAction(title: "Set Low Brightness", image: UIImage(systemName: "sun.min.fill")){_ in
          SettingsManager.shared.autoAdjustmentLowPoint.set(UIScreen.main.brightness)
          SettingsManager.shared.settingsDidChange()
          
          HUDManager.shared.displayMessage(message: .autoAdjustmentSetLow)
        }
      ].reversed())
    ])
    newButton.adjustsImageWhenHighlighted = false
    newButton.showsMenuAsPrimaryAction = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
