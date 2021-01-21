import Foundation
import UIKit

protocol CoordinatedView: UIView {
  var coordinatorView: OfflineSelectCoordinatorView {get}
  
  func viewWillEnter()
  func viewWillExit()

  func panelButtonTapped(button: PanelButton)
}
