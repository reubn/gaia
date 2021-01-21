import Foundation
import Mapbox

class OfflineManager {
  private let offlineStorage = MGLOfflineStorage.shared
  
  var downloads: [MGLOfflinePack]? {
    get {offlineStorage.packs}
  }
  
  func startDownload(style: Style, bounds: MGLCoordinateBounds, fromZoomLevel: Double, toZoomLevel: Double) {
    let region = MGLTilePyramidOfflineRegion(styleURL: style.url, bounds: bounds, fromZoomLevel: fromZoomLevel, toZoomLevel: toZoomLevel)
      
    // Store some data for identification purposes alongside the offline pack.
    let context = try! NSKeyedArchiver.archivedData(withRootObject: style, requiringSecureCoding: true)
    
    NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
     
    MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
      if(error != nil) {
      print("Error: \(error?.localizedDescription ?? "unknown error")")
      return
    }
     
    pack!.resume()
    }
  }
  
  @objc func offlinePackProgressDidChange(notification: NSNotification) {
    if let pack = notification.object as? MGLOfflinePack,
       let context = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pack.context) as? Style {

      // At this point, the offline pack has finished downloading.

      if pack.state == .complete {

      let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)


      print("""
      Offline pack completed download:
      - Bytes: \(byteCount)
      - Resource count: \(pack.progress.countOfResourcesCompleted)")
      """)

      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MGLOfflinePackProgressChanged,
      object: nil)
      }
    }

    // Reload the table to update the progress percentage for each offline pack.
//    self.tableView.reloadData()

  }
  
}
