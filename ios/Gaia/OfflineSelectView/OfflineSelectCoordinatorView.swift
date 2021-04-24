import Foundation
import UIKit

import Mapbox

class OfflineSelectCoordinatorView: CoordinatorView {
  unowned let panelViewController: OfflineSelectPanelViewController
  
  var selectedArea: MGLCoordinateBounds?
  var selectedLayers: [Layer]?
  var selectedZoom: PackContext.ZoomBounds?

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
    let layers = selectedLayers!.filter({$0.group != "gpx"}).sorted(by: LayerManager.shared.layerSortingFunction)
    
    let context = PackContext(
      layers: layers.map({$0.id}),
      bounds: selectedArea!,
      name: DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short),
      zoom: selectedZoom!
    )
    
    OfflineManager.shared.downloadPack(layers: layers, context: context)
    
    let revealedLayers = LayerManager.shared.compositeStyle.revealedLayers
    LayerManager.shared.filter({revealedLayers.contains($0)})
    
    super.done()
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




