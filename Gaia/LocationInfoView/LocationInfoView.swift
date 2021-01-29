import Foundation
import UIKit

import Mapbox

class LocationInfoView: UIScrollView {
  let mapViewController: MapViewController
  let panelViewController: LocationInfoPanelViewController
  
  init(mapViewController: MapViewController, panelViewController: LocationInfoPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init(frame: CGRect())
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}







