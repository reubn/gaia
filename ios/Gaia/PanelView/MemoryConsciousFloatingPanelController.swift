import Foundation
import UIKit
import FloatingPanel

class MemoryConsciousFloatingPanelController: FloatingPanelController {
  let brightnessHold: BrightnessManager.Hold = .infinite()
  
  override func viewWillAppear(_ animated: Bool) {
    BrightnessManager.shared.place(hold: self.brightnessHold)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if(isBeingDismissed) {
      set(contentViewController: nil)
      delegate = nil
      
      BrightnessManager.shared.remove(hold: self.brightnessHold)
    }
  }
}
