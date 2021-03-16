import Foundation
import UIKit

class SelectableLabel: UILabel {
  var isSelectable = false
  var selectionText: String? {
    didSet {
      isSelectable = selectionText != nil
    }
  }
  
  unowned var pasteDelegate: SelectableLabelPasteDelegate?
  var isPasteable: Bool {
    get {pasteDelegate != nil}
  }
  
  init() {
    super.init(frame: CGRect())

    isUserInteractionEnabled = true
    
    let lpr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    lpr.minimumPressDuration = 0.25

    addGestureRecognizer(lpr)
  }
  
  override var canBecomeFirstResponder: Bool {
    return isSelectable || isPasteable
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return (isSelectable && action == #selector(copy(_:)))
        || (isPasteable && action == #selector(paste(_:)) && UIPasteboard.general.hasStrings)
  }

  override func copy(_ sender: Any?) {
    UIPasteboard.general.string = selectionText ?? text
  }
  
  override func paste(_ sender: Any?) {
    pasteDelegate!.userDidPaste(content: UIPasteboard.general.string!)
  }

  @objc func handleLongPress(_ recogniser: UIGestureRecognizer) {
    if(!(isSelectable || isPasteable)) {return}
    
    if(recogniser.state == .began) {
      becomeFirstResponder()
      UIMenuController.shared.showMenu(from: self, rect: self.textRect(forBounds: bounds, limitedToNumberOfLines: 0))
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

protocol SelectableLabelPasteDelegate: AnyObject {
  func userDidPaste(content: String)
}
