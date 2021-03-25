import Foundation
import UIKit

struct LayerGroup {
  let id: String
  let name: String
  let colour: UIColor
  
  var selectionFunction: (() -> [Layer])? = nil
  
  func getLayers() -> [Layer] {
    if(selectionFunction == nil) {
      return LayerManager.shared.getLayers(layerGroup: self)
    } else {
      return selectionFunction!()
    }
  }
}
