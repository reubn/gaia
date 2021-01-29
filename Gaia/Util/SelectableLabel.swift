import Foundation
import UIKit

class SelectableLabel: UILabel {
  var isSelectable = false
  var textToSelect: String?
  
  init() {
    super.init(frame: CGRect())

    isUserInteractionEnabled = true
    
    let lpr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    lpr.minimumPressDuration = 0.25

    addGestureRecognizer(lpr)
  }
  
  override var canBecomeFirstResponder: Bool {
    return isSelectable
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return action == #selector(copy(_:))
  }

  override func copy(_ sender: Any?) {
    UIPasteboard.general.string = textToSelect ?? text
  }

  @objc func handleLongPress(_ recogniser: UIGestureRecognizer) {
    if(!isSelectable) {return}
    
    if(recogniser.state == .began) {
      becomeFirstResponder()
      UIMenuController.shared.showMenu(from: self, rect: self.textRect(forBounds: frame, limitedToNumberOfLines: 1))
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

