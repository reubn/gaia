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
      self.offlineMode = !self.networkConfiguration.connected
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
  }
  
  func downloadPack(layers: [Layer], bounds: MGLCoordinateBounds, fromZoomLevel: Double, toZoomLevel: Double) {
    let compositeStyle = CompositeStyle(sortedLayers: layers)
    let region = MGLTilePyramidOfflineRegion(styleURL: compositeStyle.url, bounds: bounds, fromZoomLevel: fromZoomLevel, toZoomLevel: toZoomLevel)
    
    let layerMetadata = layers.map {LayerDefinition.Metadata($0)}
      
    let packContext = PackContext(
      layerMetadata: layerMetadata,
      style: compositeStyle.style,
      bounds: PackContext.Bounds(bounds),
      name: DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short),
      toZoomLevel: Int(toZoomLevel),
      fromZoomLevel: Int(fromZoomLevel)
    )
    
    var context: Data
    
    do {
      let encoder = JSONEncoder()
      
      context = try encoder.encode(packContext)
    } catch {return}
    
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
  let layerMetadata: [LayerDefinition.Metadata]
  let style: Style
  let bounds: Bounds
  let name: String
  let toZoomLevel: Int?
  let fromZoomLevel: Int?
  
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
