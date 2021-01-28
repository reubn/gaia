import Foundation
import UIKit

protocol CoordinatedView: UIView {
  func viewWillEnter()
  func viewWillExit()

  func panelButtonTapped(button: PanelButton)
}
