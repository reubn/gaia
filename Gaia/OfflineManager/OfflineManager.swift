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
    let packContext = PackContext(
      style: style.jsonObject,
      bounds: PackContext.Bounds(bounds),
      name: DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short)
    )
    
    var context: Data
    
    do {
      let encoder = JSONEncoder()

      context = try encoder.encode(packContext)
    } catch {
      return
    }
    
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
}

protocol OfflineManagerDelegate {
  func downloadDidUpdate(pack: MGLOfflinePack?)
}

protocol OfflineModeDelegate {
  func offlineModeDidChange(offline: Bool)
}

struct PackContext: Codable {
  let style: StyleJSON
  let bounds: Bounds
  let name: String
  
  struct Bounds: Codable {
    let ne, sw: Coordinate
    
    struct Coordinate: Codable {
      let latitude, longitude: Double
    }
  }
}

extension CLLocationCoordinate2D {
  init(_ coordinate: PackContext.Bounds.Coordinate) {
    self = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
}

extension MGLCoordinateBounds {
  init(_ bounds: PackContext.Bounds) {
    self = .init(sw: CLLocationCoordinate2D(bounds.sw), ne: CLLocationCoordinate2D(bounds.ne))
  }
}

extension PackContext.Bounds {
  init(_ bounds: MGLCoordinateBounds) {
    ne = PackContext.Bounds.Coordinate(bounds.ne)
    sw = PackContext.Bounds.Coordinate(bounds.sw)
  }
}

extension PackContext.Bounds.Coordinate {
  init(_ coordinate: CLLocationCoordinate2D) {
    self = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
}
