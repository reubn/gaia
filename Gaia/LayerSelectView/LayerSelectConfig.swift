import Foundation

struct LayerSelectConfig {
  var mutuallyExclusive = true
  var layerContextActions = true
  var reorderLayers = true
  
  var showPinned = true
  var showDisabled = true
  var showUngrouped = true
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
}

protocol LayerEditDelegate: class {
  func requestLayerEdit(_ request: LayerEditRequest) -> ()
}
