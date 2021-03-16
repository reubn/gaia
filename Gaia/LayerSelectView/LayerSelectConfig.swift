import Foundation

struct LayerSelectConfig {
  var mutuallyExclusive: Bool = true
  var layerContextActions: Bool = true
  var reorderLayers: Bool = true
  
  var showPinned: Bool = true
  var showDisabled: [ShowDisabledStyle] = [.section]
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
  
  enum ShowDisabledStyle {
    case inline
    case section
  }
}

protocol LayerEditDelegate: class {
  func layerEditWasRequested(layer: Layer) -> ()
  func layerEditWasRequested(duplicateFromLayer: Layer) -> ()
}
