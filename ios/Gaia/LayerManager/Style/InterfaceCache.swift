import Foundation

class InterfacedCache {
  let layersLock = NSLock()
  
  private var _layers: [Int: Style.InterfacedLayer] = [:]
  var layers: [Int: Style.InterfacedLayer] {
    get {
      layersLock.lock()
      defer {layersLock.unlock()}
      
      return _layers
    }
    
    set {
      layersLock.lock()
      defer {layersLock.unlock()}
      
      _layers = newValue
    }
  }
  
  let sourcesLock = NSLock()
  
  private var _sources: [Int: Style.InterfacedSource] = [:]
  var sources: [Int: Style.InterfacedSource] {
    get {
      sourcesLock.lock()
      defer {sourcesLock.unlock()}
      
      return _sources
    }
    
    set {
      sourcesLock.lock()
      defer {sourcesLock.unlock()}
      
      _sources = newValue
    }
  }
  
  static let shared = InterfacedCache()
}
