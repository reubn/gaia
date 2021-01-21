import Foundation
import UIKit

import Mapbox

class OfflineSelectCoordinatorView: UIScrollView {
  let offlineManager = OfflineManager()
  let mapViewController: MapViewController
  let panelViewController: OfflineSelectPanelViewController
  
  lazy var story: [CoordinatedView] = [
    OfflineSelectHome(coordinatorView: self, offlineManager: offlineManager),
    OfflineSelectArea(coordinatorView: self),
    OfflineSelectLayers(coordinatorView: self, layerManager: mapViewController.layerManager!)
  ]
  
  var storyPosition = -1
  
  init(mapViewController: MapViewController, panelViewController: OfflineSelectPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init(frame: CGRect())
    
    read()
    
//    self.backgroundColor = UIColor.red
//    self.isUserInteractionEnabled = false
    
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func read(direction: Int = 1){
    
    let previousChapter = storyPosition >= 0 && storyPosition < story.count ? story[storyPosition] : nil
    
    let testStoryNextPosition = storyPosition + direction
    
    if(testStoryNextPosition < 0 || testStoryNextPosition >= story.count) {return}
    
    storyPosition = testStoryNextPosition
    
    let chapter = story[storyPosition]
    
    previousChapter?.viewWillExit()
    previousChapter?.removeFromSuperview()
    
    chapter.viewWillEnter()
    addSubview(chapter)
  }
  
  func forward(){
    read(direction: 1)
  }
  
  func back(){
    read(direction: -1)
  }
  
  
//  @objc func startNewDownloadFlow(){
//    let mapView = mapViewController.mapView
//    mapViewController.osfpc.move(to: .tip, animated: true)
//    panelViewController.title = "Select Area"
//    panelViewController.buttons = [.accept, .reject]
//
////    offlineManager.startDownload(style: map, bounds: <#T##MGLCoordinateBounds#>, fromZoomLevel: <#T##Double#>, toZoomLevel: <#T##Double#>)
//  }
  
  func panelButtonTapped(button: PanelButton) {
    story[storyPosition].panelButtonTapped(button: button)
//    func acceptButtonTapped(){
//      mapViewController.osfpc.move(to: .full, animated: true)
//      panelViewController.title = "Select Layers"
//      panelViewController.buttons = [.okay]
//    }
//    
//    func rejectButtonTapped(){
//      print("reject")
//    }
  }

}




