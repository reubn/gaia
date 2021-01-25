import Foundation
import UIKit

import Mapbox

class OfflineSelectCoordinatorView: UIScrollView {
  let mapViewController: MapViewController
  let panelViewController: OfflineSelectPanelViewController
  
  var storyPosition = -1
  
  var selectedArea: MGLCoordinateBounds?
  var selectedZoom: Double?
  var selectedStyle: Style?
  var selectedZoomFrom: Double?
  var selectedZoomTo: Double?
  
  lazy var offlineManager = mapViewController.offlineManager
  
  lazy var story: [CoordinatedView] = [
    OfflineSelectHome(coordinatorView: self, mapViewController: mapViewController),
    OfflineSelectArea(coordinatorView: self),
    OfflineSelectLayers(coordinatorView: self, mapViewController: mapViewController),
    OfflineSelectZoom(coordinatorView: self)
  ]
  
  init(mapViewController: MapViewController, panelViewController: OfflineSelectPanelViewController){
    self.mapViewController = mapViewController
    self.panelViewController = panelViewController
    
    super.init(frame: CGRect())

    read()
  }
  
  private func read(direction: Int = 1, newPosition: Int? = nil){
    let previousChapter = storyPosition >= 0 && storyPosition < story.count ? story[storyPosition] : nil
    
    let testStoryNextPosition = newPosition ?? storyPosition + direction
    
    if(testStoryNextPosition < 0) {return}
    if(testStoryNextPosition >= story.count) {
      done()
      return
    }
    
    storyPosition = testStoryNextPosition
    
    let chapter = story[storyPosition]
    
    previousChapter?.viewWillExit()
    previousChapter?.removeFromSuperview()
    
    chapter.viewWillEnter()
    addSubview(chapter)
    
    chapter.translatesAutoresizingMaskIntoConstraints = false
    chapter.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
    chapter.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    chapter.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    chapter.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: UIApplication.shared.windows.first!.safeAreaInsets.bottom).isActive = true // Bug?? Normal bottomAnchor doesn't work
    
  }
  
  func forward(){
    read(direction: 1)
  }
  
  func back(){
    read(direction: -1)
  }
  
  func done(){
    offlineManager.downloadPack(style: selectedStyle!, bounds: selectedArea!, fromZoomLevel: selectedZoom! - 2, toZoomLevel: selectedZoom!)
    read(newPosition: 0)
  }
  
  func panelButtonTapped(button: PanelButton) {
    story[storyPosition].panelButtonTapped(button: button)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




