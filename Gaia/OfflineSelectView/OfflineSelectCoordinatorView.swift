import Foundation
import UIKit

import Mapbox

class OfflineSelectCoordinatorView: CoordinatorView {
  unowned let panelViewController: OfflineSelectPanelViewController
  
  var selectedArea: MGLCoordinateBounds?
  var selectedZoom: Double?
  var selectedLayers: [Layer]?
  var selectedZoomFrom: Double?
  var selectedZoomTo: Double?

  init(panelViewController: OfflineSelectPanelViewController){
    self.panelViewController = panelViewController
    
    super.init()
    
    story = [
      OfflineSelectHome(coordinatorView: self),
      OfflineSelectArea(coordinatorView: self),
      OfflineSelectLayers(coordinatorView: self),
      OfflineSelectZoom(coordinatorView: self)
    ]
    
    super.ready()
  }
  
  override func done(){
    OfflineManager.shared.downloadPack(layers: selectedLayers!, bounds: selectedArea!, fromZoomLevel: selectedZoom! - 2, toZoomLevel: selectedZoom!)
    
    super.done()
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




