import Foundation
import Mapbox

class OfflineManager {
  private let offlineStorage = MGLOfflineStorage.shared
  private let networkConfiguration = MGLNetworkConfiguration()
  
  var offlineMode = false {
    didSet {
      print("offlinemode set to \(offlineMode)")
      networkConfiguration.connected = !offlineMode
      self.multicastOfflineModeDidChangeDelegate.invoke(invocation: {$0.offlineModeDidChange(offline: offlineMode)})
    }
  }
  
  let multicastDownloadDidUpdateDelegate = MulticastDelegate<(OfflineManagerDelegate)>()
  let multicastOfflineModeDidChangeDelegate = MulticastDelegate<(OfflineModeDelegate)>()
  
  var downloads: [MGLOfflinePack]? {
    get {offlineStorage.packs}
  }
  
  init() {
    NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
    
    DispatchQueue.main.async {
      self.refreshDownloads()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
  }
  
  func downloadPack(style: Style, bounds: MGLCoordinateBounds, fromZoomLevel: Double, toZoomLevel: Double) {
    let region = MGLTilePyramidOfflineRegion(styleURL: style.url, bounds: bounds, fromZoomLevel: fromZoomLevel, toZoomLevel: toZoomLevel)
      
    // Store some data for identification purposes alongside the offline pack.
    let context = style.jsonData!
    
    MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
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
  
  
  @objc func offlinePackProgressDidChange(notification: NSNotification) {
    multicastDownloadDidUpdateDelegate.invoke(invocation: {$0.downloadDidUpdate(pack: notification.object as? MGLOfflinePack)})
  }
  
  func refreshDownloads(){
    for pack in downloads ?? [] {
      pack.requestProgress()
    }
  }
}

protocol OfflineManagerDelegate {
  func downloadDidUpdate(pack: MGLOfflinePack?)
}

protocol OfflineModeDelegate {
  func offlineModeDidChange(offline: Bool)
}
