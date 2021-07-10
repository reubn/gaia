import Foundation
import UIKit

import Mapbox

class OfflineSelectHome: UIView, CoordinatedView, UITableViewDelegate, UITableViewDataSource, OfflineManagerDelegate, OfflineModeDelegate, MapViewStyleDidChangeDelegate {

  func styleDidChange() {
    (mapSource as? MGLShapeSource)?.shape = rectangle
    _ = mapLayer
  }
  
  unowned let coordinatorView: OfflineSelectCoordinatorView

  lazy var emptyState = OfflineSelectHomeEmpty()
  
  lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.75)
    scrollView.layer.cornerRadius = 8
    scrollView.layer.cornerCurve = .continuous
    scrollView.clipsToBounds = true
    
    scrollView.addSubview(tableView)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true

    return scrollView
  }()

  lazy var tableView: UITableView = {
    let tableView = DownloadsTableView()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear

    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.isScrollEnabled = false
    
    return tableView
  }()
  
  var rectangle: MGLPolylineFeature? {
    didSet {
      (mapSource as? MGLShapeSource)?.shape = rectangle
      _ = mapLayer
    }
  }
  
  var mapSource: MGLSource {
    MapViewController.shared.mapView.style?.source(withIdentifier: "offlinePreview") ?? {
      let source = MGLShapeSource(identifier: "offlinePreview", features: [])
      
      MapViewController.shared.mapView.style?.addSource(source)
      
      return source
    }()
  }
  
  var mapLayer: MGLStyleLayer {
    MapViewController.shared.mapView.style?.layer(withIdentifier: "offlinePreview") ?? {
      let layer = MGLLineStyleLayer(identifier: "offlinePreview", source: mapSource)
      
      layer.lineColor = NSExpression(forConstantValue: UIColor.systemRed)
      layer.lineWidth = NSExpression(forConstantValue: 2.0)
      
      MapViewController.shared.mapView.style?.addLayer(layer)
      
      return layer
    }()
  }
  
  init(coordinatorView: OfflineSelectCoordinatorView){
    self.coordinatorView = coordinatorView
 
    super.init(frame: CGRect())
    
    OfflineManager.shared.multicastDownloadDidUpdateDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    MapViewController.shared.multicastMapViewStyleDidChangeDelegate.add(delegate: self)
    
    addSubview(emptyState)
    
    emptyState.translatesAutoresizingMaskIntoConstraints = false
    emptyState.topAnchor.constraint(equalTo: topAnchor).isActive = true
    emptyState.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    emptyState.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor).isActive = true
    
    addSubview(scrollView)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
  }
  
  func viewWillEnter(data: Any?){
    print("enter OSH")

    if(MapViewController.shared.osfpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.osfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Downloads"
    coordinatorView.panelViewController.panelButtons = [.new, .dismiss]
    
    offlineModeDidChange(offline: OfflineManager.shared.offlineMode)
    
    OfflineManager.shared.refreshDownloads()
    
    emptyState.update()
  }
  
  func viewWillExit(){
    print("exit OSH")
    rectangle = nil
    
    MapViewController.shared.mapView.style?.removeSource(mapSource)
    MapViewController.shared.mapView.style?.removeLayer(mapLayer)
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .dismiss) {coordinatorView.panelViewController.dismiss(animated: true, completion: nil)}
    else if(button == .new) {coordinatorView.forward()}
  }
  
  func offlineModeDidChange(offline: Bool) {
    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
    newButton.isEnabled = !LayerManager.shared.compositeStyle.sortedLayers.isEmpty && !offline
  }
  
  func downloadDidUpdate(pack: MGLOfflinePack?) {
    defer {
      scrollView.contentSize.height = tableView.intrinsicContentSize.height
    }
    
    if(pack != nil){
      let index = OfflineManager.shared.downloads!.firstIndex(of: pack!)
      
      if(index == nil) {
        update()
        
        return
      }
      
      let indexPath = IndexPath(row: index!, section: 0)
      let cell = tableView.cellForRow(at: indexPath) as? DownloadCell
      
      if(cell != nil) {cell!.update(pack: pack!)}
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
    if let packs = OfflineManager.shared.downloads {
      return packs.count
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = DownloadCell(style: .subtitle, reuseIdentifier: "cell")
     
    cell.update(pack: OfflineManager.shared.downloads![indexPath.row])
     
    return cell
   
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let downloads = OfflineManager.shared.downloads!
    
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
            OfflineManager.shared.redownloadPack(pack: pack)
        })
        
        children.append(UIAction(
          title: "Share",
          image: UIImage(systemName: "square.and.arrow.up")) { _ in
            if let context = OfflineManager.shared.decodePackContext(pack: pack),
               let url = URLInterface.shared.encode(commands: [.download(context)]) {
              let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
              activityViewController.popoverPresentationController?.sourceView = tableView
              MapViewController.shared.osfpc.present(activityViewController, animated: true, completion: nil)
            }
        })
      } else if(pack.state == .active) {
        let action = UIAction(
          title: "Stop Download",
          image: UIImage(systemName: "xmark.circle"),
          attributes: .destructive) { _ in
            pack.suspend()
        }
        
        children.append(action)
      }
      
      let delete = UIAction(
        title: "Delete",
        image: UIImage(systemName: "trash"),
        attributes: .destructive) { _ in
          OfflineManager.shared.deletePack(pack: pack)
      }
      
      children.append(delete)
      
    
      return UIMenu(title: "", children: children)
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let pack = OfflineManager.shared.downloads![indexPath.row]
    
    previewPack(pack: pack)
    
  }
  
  func previewPack(pack: MGLOfflinePack){
    let context = OfflineManager.shared.decodePackContext(pack: pack)!
    let bounds = context.bounds
    
    let layers = LayerManager.shared.layers.filter({
      context.layers.contains($0.id)
    }).sorted(by: LayerManager.shared.layerSortingFunction)
    let compositeStyle = CompositeStyle(sortedLayers: layers)
    let revealedLayers = compositeStyle.revealedLayers
    
    let corners = [bounds.ne, bounds.nw, bounds.sw, bounds.se, bounds.ne]
    rectangle = MGLPolylineFeature(coordinates: corners, count: UInt(corners.count))
    
    LayerManager.shared.filter({revealedLayers.contains($0)})
    
    MapViewController.shared.mapView.setDirection(0, animated: false)
    MapViewController.shared.mapView.setVisibleCoordinateBounds(bounds, sensible: true, alwaysShowWhole: true, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
