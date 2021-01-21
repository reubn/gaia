import Foundation
import UIKit

import Mapbox

class OfflineSelectHome: UIStackView, CoordinatedView, UITableViewDelegate, UITableViewDataSource {
  let coordinatorView: OfflineSelectCoordinatorView
  var offlineManager: OfflineManager

  lazy var newButton: UIButton = {
    let button = UIButton(frame: CGRect.zero)
    button.backgroundColor = UIColor.systemBlue
    button.setTitleColor(UIColor.white, for: .normal)
    button.setTitle("Download Region", for: .normal)
    button.addTarget(self, action: #selector(newButtonTapped), for: .touchUpInside)
    button.layer.cornerRadius = bounds.width / 30
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()
   
  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: CGRect.zero)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  }()
  
  init(coordinatorView: OfflineSelectCoordinatorView, offlineManager: OfflineManager){
    self.coordinatorView = coordinatorView
    self.offlineManager = offlineManager
    
    super.init(frame: CGRect())
    
    axis = .vertical
    alignment = .leading
    distribution = .fill
    spacing = 30
    translatesAutoresizingMaskIntoConstraints = false
    
    backgroundColor = UIColor.orange
    
    addArrangedSubview(tableView)
    addArrangedSubview(newButton)
//    layerManager.layerGroups.forEach({
//      if(layerManager.getLayers(layerGroup: $0) == nil) {return}
//
//      let section = Section(group: $0, layerManager: layerManager)
//
//      addArrangedSubview(section)
//
//      section.translatesAutoresizingMaskIntoConstraints = false
//      section.widthAnchor.constraint(equalTo: widthAnchor, constant: -30).isActive = true
//    })
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSH")
  }
  
  func viewWillExit(){
    print("exit OSH")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .dismiss) {
      coordinatorView.panelViewController.dismiss(animated: true, completion: nil)
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return UITableViewCell()
  }
  
  @objc func newButtonTapped(){
    coordinatorView.forward()
  }
  
}





