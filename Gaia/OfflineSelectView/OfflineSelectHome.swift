import Foundation
import UIKit

import Mapbox

class OfflineSelectHome: UIView, CoordinatedView, UITableViewDelegate, UITableViewDataSource {
  let coordinatorView: OfflineSelectCoordinatorView
  var offlineManager: OfflineManager

  lazy var newButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
    button.tintColor = .systemBlue
    button.backgroundColor = .white
    button.layer.cornerRadius = 8
    button.layer.cornerCurve = .continuous

    button.addTarget(self, action: #selector(self.newButtonTapped), for: .touchUpInside)
    
    addSubview(button)
    
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 60).isActive = true
    button.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
    button.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    button.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    return button
  }()
   
  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: CGRect.zero)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .systemPink
    return tableView
  }()
  
  init(coordinatorView: OfflineSelectCoordinatorView, offlineManager: OfflineManager){
    self.coordinatorView = coordinatorView
    self.offlineManager = offlineManager
    
    super.init(frame: CGRect())
    
//    translatesAutoresizingMaskIntoConstraints = false
    
//    backgroundColor = UIColor.orange
    
    addSubview(tableView)
//    addSubview(newButton)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: newButton.topAnchor, constant: -20).isActive = true
    tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func viewWillEnter(){
    print("enter OSH")
    coordinatorView.mapViewController.osfpc.move(to: .full, animated: true)
    coordinatorView.panelViewController.title = "Downloads"
    coordinatorView.panelViewController.buttons = [.dismiss]
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
    if let packs = offlineManager.downloads {
      return packs.count
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   
    let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
     
    if let packs = offlineManager.downloads {
      let pack = packs[indexPath.row]
       
      cell.textLabel?.text = "Region \(indexPath.row + 1): size: \(pack.progress.countOfBytesCompleted)"
      cell.detailTextLabel?.text = "Percent completion: \(pack.progress.countOfResourcesExpected != 0 ? String(pack.progress.countOfResourcesCompleted / pack.progress.countOfResourcesExpected) : "N/A")%"
    }
     
    return cell
   
  }
  
  @objc func newButtonTapped(){
    coordinatorView.forward()
  }
  
}





