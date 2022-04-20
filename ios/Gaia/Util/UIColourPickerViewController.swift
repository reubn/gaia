import Foundation
import UIKit

class UIColourPickerViewController: UIColorPickerViewController {
  var publisher: Any?
  
  init(callback: @escaping (UIColor) -> Void){
    super.init()
    
    publisher = self.publisher(for: \.selectedColor)
      .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
      .sink(receiveValue: callback)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}





