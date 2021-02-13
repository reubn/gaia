import Foundation
import UIKit

import Mapbox

class OfflineSelectHome: UIView, CoordinatedView, UITableViewDelegate, UITableViewDataSource, OfflineManagerDelegate {
  unowned let coordinatorView: OfflineSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  lazy var offlineManager = mapViewController.offlineManager
  
  lazy var emptyState = OfflineSelectHomeEmpty(offlineManager: offlineManager)

  lazy var tableView: UITableView = {
    let tableView = DownloadsTableView()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.75)
    
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
    
    addSubview(emptyState)
    
    emptyState.translatesAutoresizingMaskIntoConstraints = false
    emptyState.topAnchor.constraint(equalTo: topAnchor).isActive = true
    emptyState.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    emptyState.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor).isActive = true
    
    addSubview(tableView)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSH")
    
    if(coordinatorView.mapViewController.osfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.osfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Downloads"
    coordinatorView.panelViewController.panelButtons = [.new, .dismiss]
    
    offlineManager.refreshDownloads()
    
    emptyState.update()
  }
  
  func viewWillExit(){
    print("exit OSH")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .dismiss) {coordinatorView.panelViewController.dismiss(animated: true, completion: nil)}
    else if(button == .new) {coordinatorView.forward()}
  }
  
  func downloadDidUpdate(pack: MGLOfflinePack?) {
    if(pack != nil){
      let index = offlineManager.downloads!.firstIndex(of: pack!)
      
      if(index == nil) {
        update()
        
        return
      }
      
      let indexPath = IndexPath(row: index!, section: 0)
      let cell = tableView.cellForRow(at: indexPath) as? DownloadCell
      
      if(cell != nil) {cell!.update(pack: pack!, mapViewController: mapViewController)}
      else {update()}
    } else {
      update()
    }
  }
  
  func update(){
    emptyState.update()
    tableView.reloadData()
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
        children.append(UIAction(
          title: "Preview",
          image: UIImage(systemName: "eye")) { _ in
            self.previewPack(pack: pack)
        })
        
        children.append(UIAction(
          title: "Redownload",
          image: UIImage(systemName: "square.and.arrow.down")) { _ in
            self.offlineManager.redownloadPack(pack: pack)
        })
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
    
    previewPack(pack: pack)
    
  }
  
  func previewPack(pack: MGLOfflinePack){
    let context = offlineManager.decodePackContext(pack: pack)!

    let bounds = MGLCoordinateBounds(context.bounds)
    
    layerManager.filterLayers({layer in
      context.layerMetadata.contains(where: {layerMetadata in
        layerMetadata.id == layer.id
      })
    })
    
    mapViewController.mapView.setDirection(0, animated: false)
    mapViewController.mapView.setVisibleCoordinateBounds(bounds, animated: true)
    coordinatorView.mapViewController.osfpc.dismiss(animated: true, completion: nil)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
