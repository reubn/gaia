import Foundation

struct LayerSelectConfig {
  let mutuallyExclusive: Bool
  let layerContextActions: Bool
  let reorderLayers: Bool
  
  unowned let layerEditDelegate: LayerEditDelegate?
}

protocol LayerEditDelegate: class {
  func layerEditWasRequested(layer: Layer) -> ()
}
