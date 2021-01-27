import Foundation
import UIKit

import Mapbox

class OfflineSelectCoordinatorView: CoordinatorView {
  let mapViewController: MapViewController
  let panelViewController: OfflineSelectPanelViewController
  
  var selectedArea: MGLCoordinateBounds?
  var selectedZoom: Double?
  var selectedStyle: Style?
  var selectedZoomFrom: Double?
  var selectedZoomTo: Double?
  
  lazy var offlineManager = mapViewController.offlineManager

  init(mapViewController: MapViewController, panelViewController: OfflineSelectPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init()
    
    story = [
      OfflineSelectHome(coordinatorView: self, mapViewController: mapViewController),
      OfflineSelectArea(coordinatorView: self),
      OfflineSelectLayers(coordinatorView: self, mapViewController: mapViewController),
      OfflineSelectZoom(coordinatorView: self)
    ]
    
    super.ready()
  }
  
  override func done(){
    offlineManager.downloadPack(style: selectedStyle!, bounds: selectedArea!, fromZoomLevel: selectedZoom! - 2, toZoomLevel: selectedZoom!)
    
    super.done()
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




