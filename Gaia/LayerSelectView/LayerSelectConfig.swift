import Foundation

struct LayerSelectConfig {
  var mutuallyExclusive: Bool = true
  var layerContextActions: Bool = true
  var reorderLayers: Bool = true
  
  var showFavourites: Bool = true
  
  unowned var layerEditDelegate: LayerEditDelegate? = nil
}

protocol LayerEditDelegate: class {
  func layerEditWasRequested(layer: Layer) -> ()
}
