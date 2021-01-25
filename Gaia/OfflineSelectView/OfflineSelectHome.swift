import Foundation
import UIKit

import Mapbox

class OfflineSelectHome: UIView, CoordinatedView, UITableViewDelegate, UITableViewDataSource, OfflineManagerDelegate {
  let coordinatorView: OfflineSelectCoordinatorView
  let mapViewController: MapViewController
  lazy var layerManager = mapViewController.layerManager
  lazy var offlineManager = mapViewController.offlineManager

//  lazy var newButton: UIButton = {
//    let button = UIButton()
//    button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
//    button.contentVerticalAlignment = .fill
//    button.contentHorizontalAlignment = .fill
//    button.imageView!.contentMode = .scaleAspectFit
//    button.imageEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
//    button.tintColor = .systemBlue
//    button.backgroundColor = .white
//    button.layer.cornerRadius = 8
//    button.layer.cornerCurve = .continuous
//
//    button.addTarget(self, action: #selector(self.newButtonTapped), for: .touchUpInside)
//
//    addSubview(button)
//
//    button.translatesAutoresizingMaskIntoConstraints = false
//    button.heightAnchor.constraint(equalToConstant: 60).isActive = true
//    button.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
//    button.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
//    button.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
//
//    return button
//  }()
   
  lazy var tableView: UITableView = {
    let tableView = STableView()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    
    tableView.layer.cornerRadius = 8
    tableView.layer.cornerCurve = .continuous
    tableView.clipsToBounds = true
    
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.isScrollEnabled = false
    return tableView
  }()
  
  init(coordinatorView: OfflineSelectCoordinatorView, mapViewController: MapViewController){
    self.coordinatorView = coordinatorView
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())
    
    offlineManager.multicastDownloadDidUpdateDelegate.add(delegate: self)
    
//    translatesAutoresizingMaskIntoConstraints = false
    
//    backgroundColor = UIColor.orange
    
    addSubview(tableView)
//    addSubview(newButton)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
//    tableView.bottomAnchor.constraint(lessThanOrEqualTo: newButton.topAnchor, constant: -20).isActive = true
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
    coordinatorView.panelViewController.buttons = [.new, .dismiss]
    
    offlineManager.refreshDownloads()
  }
  
  func viewWillExit(){
    print("exit OSH")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .dismiss) {coordinatorView.panelViewController.dismiss(animated: true, completion: nil)}
    else if(button == .new) {coordinatorView.forward()}
  }
  
  func downloadDidUpdate(pack: MGLOfflinePack?) {
    print("pack change")

    if(pack != nil){
      let index = offlineManager.downloads!.firstIndex(of: pack!)
      let indexPath = IndexPath(row: index!, section: 0)
      let cell = tableView.cellForRow(at: indexPath) as? DownloadCell
      
      if(cell != nil) {cell!.update(pack: pack!, mapViewController: mapViewController)}
      else {tableView.reloadData()}
    } else {
      tableView.reloadData()
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
    let cell = DownloadCell(style: .subtitle, reuseIdentifier: "cell")
     
    cell.update(pack: offlineManager.downloads![indexPath.row], mapViewController: mapViewController)
     
    return cell
   
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let downloads = offlineManager.downloads!
    
    if(downloads.count <= indexPath.row) {
      return nil
    }
    
    let pack = downloads[indexPath.row]
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){ actions -> UIMenu? in
      
      var children: [UIAction] = []
      
      if(pack.state == .inactive) {
        let action = UIAction(
          title: "Resume",
          image: UIImage(systemName: "square.and.arrow.down")) { _ in
            pack.resume()
        }
        
        children.append(action)
      }
      
      if(pack.state == .complete) {
        let action = UIAction(
          title: "Redownload",
          image: UIImage(systemName: "square.and.arrow.down")) { _ in
            self.offlineManager.redownloadPack(pack: pack)
        }
        
        children.append(action)
      }
      
      if(pack.state == .active) {
        let action = UIAction(
          title: "Stop Download",
          image: UIImage(systemName: "xmark.circle.fill"),
          attributes: .destructive) { _ in
            pack.suspend()
        }
        
        children.append(action)
      }
      
      let delete = UIAction(
        title: "Delete",
        image: UIImage(systemName: "trash"),
        attributes: .destructive) { _ in
          self.offlineManager.deletePack(pack: pack)
      }
      
      children.append(delete)
      
    
      return UIMenu(title: "", children: children)
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let pack = offlineManager.downloads![indexPath.row]
    let context = offlineManager.decodePackContext(pack: pack)!
    
//    let currentBounds
    let bounds = MGLCoordinateBounds(context.bounds)
    
    layerManager.filterLayers({layer in
      context.style.layers.contains(where: {jsonLayer in
        jsonLayer.id == layer.id
      })
    })
    
    mapViewController.mapView.setDirection(0, animated: false)
    mapViewController.mapView.setVisibleCoordinateBounds(bounds, animated: true)
    coordinatorView.mapViewController.osfpc.dismiss(animated: true, completion: nil)
    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//        self.yourFuncHere()
//    }
  }
  
//  @objc func newButtonTapped(){
//    coordinatorView.forward()
//  }
  
}





class STableView: UITableView {
  init(){
    super.init(frame: CGRect(), style: UITableView.Style.plain)
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var contentSize: CGSize {
    didSet {
        invalidateIntrinsicContentSize()
    }
  }

  override var intrinsicContentSize: CGSize {
    layoutIfNeeded()
    return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
  }
}
