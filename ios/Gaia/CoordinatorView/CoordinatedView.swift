import Foundation
import UIKit

protocol CoordinatedView: UIView {
  func viewWillEnter(data: Any?)
  func viewWillExit()

  func panelButtonTapped(button: PanelButtonType)
}
