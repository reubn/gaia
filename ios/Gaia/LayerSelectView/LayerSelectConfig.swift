import Foundation
import UIKit

struct LayerSelectConfig {
  var mutuallyExclusive = true
  var layerContextActions = true
  var reorderLayers = true
  
  var showPinned = true
  var showUngrouped = true
  
  var filter: ((Layer) -> Bool)? = nil
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
}

protocol LayerEditDelegate: AnyObject {
  func requestLayerEdit(_ request: LayerEditRequest) -> ()
  func requestLayerColourPicker(_ colour: UIColor, supportsAlpha: Bool, callback: @escaping (UIColor) -> Void)
}
