import Foundation
import UIKit

protocol CoordinatedView: UIView {
  func viewWillEnter(data: Any?)
  func update(data: Any?)
  func viewWillExit()

  func panelButtonTapped(button: PanelButtonType)
}
