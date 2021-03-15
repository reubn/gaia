import Foundation
import UIKit

class CanvasView: UIView {
  let squareSize: CGFloat
  
  init(size: CGFloat = 20, frame: CGRect) {
    squareSize = size
    super.init(frame: frame)
  }

  override func draw(_ dirtyRect: CGRect) {
    let context = UIGraphicsGetCurrentContext()!

    for x in stride(from: 0, to: bounds.width, by: squareSize) {
      for y in stride(from: 0, to: bounds.height, by: squareSize) {
        (Int(y / squareSize) % 2 == Int(x / squareSize) % 2
          ? UIColor.systemBackground
          : UIColor.secondarySystemBackground
        ).setFill()
        
        context.fill(CGRect(x: x, y: y, width: squareSize, height: squareSize))
      }
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
