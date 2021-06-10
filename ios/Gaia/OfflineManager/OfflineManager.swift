import Foundation
import Network

import Mapbox

class OfflineManager {
  private let offlineStorage = MGLOfflineStorage.shared
  private let networkConfiguration = MGLNetworkConfiguration()
  private let monitor = NWPathMonitor()
  private let monitorQueue = DispatchQueue(label: "NWPathMonitorQueue")
  
  var isOfflineSetManually = false
  var firstTime = true
  
  var offlineMode = false {
    didSet {
      print("offlinemode set to \(offlineMode)")
      networkConfiguration.connected = !offlineMode
      self.multicastOfflineModeDidChangeDelegate.invoke(invocation: {$0.offlineModeDidChange(offline: offlineMode)})
      
      if(!(firstTime && offlineMode == false)){
        HUDManager.shared.displayMessage(message: offlineMode ? .offlineModeEnabled : .offlineModeDisabled)
      }
      
      isOfflineSetManually = true
      firstTime = false
    }
  }
  
  let multicastDownloadDidUpdateDelegate = MulticastDelegate<(OfflineManagerDelegate)>()
  let multicastOfflineModeDidChangeDelegate = MulticastDelegate<(OfflineModeDelegate)>()
  
  var downloads: [MGLOfflinePack]? {
    get {offlineStorage.packs}
  }
  
  init() {
    NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
    
    monitor.pathUpdateHandler = pathDidUpdate
    monitor.start(queue: monitorQueue)
    
    DispatchQueue.main.async {
      self.refreshDownloads()
      self.offlineMode = !self.networkConfiguration.connected
      self.isOfflineSetManually = false
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
  }
  
  func pathDidUpdate(_ path: NWPath){
    DispatchQueue.main.async {
      if(!self.isOfflineSetManually && (path.isConstrained || path.isExpensive)){
        self.offlineMode = true
        self.isOfflineSetManually = false
      }
      
      print("path update", path)
    }
  }
  
  func downloadPack(context: PackContext) {
    let layers = LayerManager.shared.layers.filter({
      context.layers.contains($0.id)
    }).sorted(by: LayerManager.shared.layerSortingFunction)
    
    downloadPack(layers: layers, context: context)
  }
  
  func downloadPack(layers: [Layer], context: PackContext) {
    let compositeStyle = CompositeStyle(sortedLayers: layers)
    let style = compositeStyle.toStyle()
    
    // Mapbox doesn't respect max + min zoom constraints: force these
    let options = style.interfacedSources.map({(source) -> Style.InterfacedSource in
      var source = source
      
      if(source.capabilities.contains(.maxZoom)) {
        source = source.setting(.maxZoom, to: context.zoom.to)
      }
      
      if(source.capabilities.contains(.minZoom)) {
        source = source.setting(.minZoom, to: context.zoom.from)
      }
      
      return source
    })
    let fixedStyle = style.with(options)
    
    let region = MGLTilePyramidOfflineRegion(styleURL: fixedStyle.url, bounds: context.bounds, fromZoomLevel: context.zoom.from, toZoomLevel: context.zoom.to)
    
    var contextData: Data
    
    do {
      let encoder = JSONEncoder()
      
      contextData = try encoder.encode(context)
    } catch {return}
    
    MGLOfflineStorage.shared.addPack(for: region, withContext: contextData) { (pack, error) in
      if(error != nil) {
        print("Error: \(error?.localizedDescription ?? "unknown error")")
        return
      }
     
      pack!.resume()
    }
  }
  
  func redownloadPack(pack: MGLOfflinePack){
    offlineStorage.invalidatePack(pack){error in
      if(error != nil) {print("Error: \(error?.localizedDescription ?? "unknown error")")}
      
      self.refreshDownloads()
      self.multicastDownloadDidUpdateDelegate.invoke(invocation: {$0.downloadDidUpdate(pack: pack)})
    }
  }
  
  func deletePack(pack: MGLOfflinePack){
    offlineStorage.removePack(pack){error in
      if(error != nil) {print("Error: \(error?.localizedDescription ?? "unknown error")")}
      
      self.refreshDownloads()
      self.multicastDownloadDidUpdateDelegate.invoke(invocation: {$0.downloadDidUpdate(pack: nil)})
    }
  }
  
  func refreshDownloads(){
    for pack in downloads ?? [] {
      pack.requestProgress()
    }
  }
  
  func decodePackContext(pack: MGLOfflinePack) -> PackContext? {
    do {
      let decoder = JSONDecoder()

      return try decoder.decode(PackContext.self, from: pack.context)
    } catch {
      return nil
    }
  }
  
  @objc func offlinePackProgressDidChange(notification: NSNotification) {
    multicastDownloadDidUpdateDelegate.invoke(invocation: {$0.downloadDidUpdate(pack: notification.object as? MGLOfflinePack)})
  }
  
  func clearCache(completionHandler: @escaping (Error?) -> Void){
    offlineStorage.clearAmbientCache(completionHandler: completionHandler)
  }
  
  static let shared = OfflineManager()
}

protocol OfflineManagerDelegate {
  func downloadDidUpdate(pack: MGLOfflinePack?)
}

protocol OfflineModeDelegate {
  func offlineModeDidChange(offline: Bool)
}

struct PackContext: Codable {
  let layers: [String]
  let bounds: MGLCoordinateBounds
  let name: String
  let zoom: ZoomBounds

  struct ZoomBounds: Codable {
    let from: Double
    let to: Double
  }
}
