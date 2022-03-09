import Foundation
import UIKit

struct LayerGroup {
  let id: String
  let name: String
  let colour: UIColor
  var icon: String? = nil
  
  var selectionFunction: (() -> [GaiaLayer])? = nil
  
  func getLayers() -> [GaiaLayer] {
    if(selectionFunction == nil) {
      return LayerManager.shared.getLayers(layerGroup: self)
    } else {
      return selectionFunction!()
    }
  }
}
