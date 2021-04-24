import Foundation
import UIKit

class SectionTableView: UITableView {
  init(){
    super.init(frame: CGRect(), style: UITableView.Style.plain)
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
  }

  override var contentSize: CGSize {
    didSet {
      invalidateIntrinsicContentSize()
    }
  }

  override var intrinsicContentSize: CGSize {
    layoutIfNeeded()
    
    return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
