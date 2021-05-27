import Foundation
import UIKit

struct LayerSelectConfig {
  var mutuallyExclusive = true
  var layerContextActions = true
  var reorderLayers = true
  
  var showPinned = true
  var showDisabled = true
  var showUngrouped = true
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
}

protocol LayerEditDelegate: AnyObject {
  func requestLayerEdit(_ request: LayerEditRequest) -> ()
  func requestLayerColourPicker(_ layer: Layer, callback: @escaping (UIColor) -> Void)
}
