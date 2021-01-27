import Foundation
import UIKit

class CoordinatorView: UIScrollView {
  var storyPosition = -1
  
  lazy var story: [CoordinatedView] = []
  
  init(){
    super.init(frame: CGRect())
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
  
  func ready(){
    read()
  }
  
  func forward(){
    read(direction: 1)
  }
  
  func back(){
    read(direction: -1)
  }
  
  func done(){
    read(newPosition: 0)
  }
  
  func panelButtonTapped(button: PanelButton) {
    story[storyPosition].panelButtonTapped(button: button)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




