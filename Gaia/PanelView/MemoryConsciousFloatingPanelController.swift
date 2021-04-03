import Foundation
import UIKit
import FloatingPanel

class MemoryConsciousFloatingPanelController: FloatingPanelController {
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if(isBeingDismissed) {
      set(contentViewController: nil)
      delegate = nil
    }
  }
}
