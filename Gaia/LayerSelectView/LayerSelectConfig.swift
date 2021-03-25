import Foundation

struct LayerSelectConfig {
  var mutuallyExclusive = true
  var layerContextActions = true
  var reorderLayers = true
  
  var showPinned = true
  var showDisabled: [ShowDisabledStyle] = [.section]
  var showUngrouped = true
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
  
  enum ShowDisabledStyle {
    case inline
    case section
  }
}

protocol LayerEditDelegate: class {
  func requestLayerEdit(_ request: LayerEditRequest) -> ()
}
