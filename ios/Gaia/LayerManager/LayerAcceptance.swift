import Foundation

enum LayerAcceptanceMethod {
  case add
  case update(Layer? = nil)
}

struct LayerAcceptanceResult {
  let method: LayerAcceptanceMethod?
  let error: LayerAcceptanceError?
  
  let layer: Layer?
  
  var accepted: Bool {
    error == nil
  }
  
  static func accepted(_ method: LayerAcceptanceMethod, layer: Layer? = nil) -> Self {
    self.init(method: method, error: nil, layer: layer)
  }
  
  static func error(_ error: LayerAcceptanceError) -> Self {
    self.init(method: nil, error: error, layer: nil)
  }
}

struct LayerAcceptanceResults {
  let submitted: [LayerAcceptanceResult]
  
  var accepted: [LayerAcceptanceResult] {
    submitted.filter({$0.accepted})
  }
  
  var rejected: [LayerAcceptanceResult] {
    submitted.filter({!$0.accepted})
  }
  
  var added: [LayerAcceptanceResult] {
    accepted.filter({if case .add = $0.method {return true} else {return false}})
  }
  
  var updated: [LayerAcceptanceResult] {
    accepted.filter({if case .update = $0.method {return true} else {return false}})
  }
}

enum LayerAcceptanceError {
  case layerExistsWithId(String)
  case noLayerExistsWithId(String)

  case unexplained
}
