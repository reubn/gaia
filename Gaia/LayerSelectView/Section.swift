import Foundation
import UIKit
import CoreData

import Mapbox

class Section: UIStackView, LayerManagerDelegate {
  let group: LayerGroup
  let layerManager: LayerManager
  let mapViewController: MapViewController
  var layers: [Layer]
  let tableView = SectionTableView()
  
  init(group: LayerGroup, layerManager: LayerManager, mapViewController: MapViewController){
    self.group = group
    self.layerManager = layerManager
    self.mapViewController = mapViewController
    self.layers = layerManager.getLayers(layerGroup: group).reversed()
    
    super.init(frame: CGRect())
    
    layerManager.multicastStyleDidChangeDelegate.add(delegate: self)
    
    axis = .vertical
    alignment = .leading
    distribution = .fill
    spacing = 10
    
    let label = SectionLabel()
    label.text = group.name.uppercased()
    label.backgroundColor = group.colour

    addArrangedSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    
    tableView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.75)
    tableView.dataSource = self
    
    tableView.dragDelegate = self // empty drag, drop delegate methods needed to enable moveRowAt... bug?
    tableView.dropDelegate = self // empty drag, drop delegate methods needed to enable moveRowAt... bug?
    tableView.dragInteractionEnabled = true
    
    tableView.isScrollEnabled = false
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.register(LayerCell.self, forCellReuseIdentifier: "cell")
    
    addArrangedSubview(tableView)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  func styleDidChange(style _: Style) {
    self.layers = layerManager.getLayers(layerGroup: group).reversed()
    
    tableView.reloadData()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension Section: UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate {
  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    return [] // empty drag, drop delegate methods needed to enable moveRowAt... bug?
  }
  
  func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {} // empty drag, drop delegate methods needed to enable moveRowAt... bug?
  
  func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
    return false // reject drops between groups
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let movedLayer = layers[sourceIndexPath.row]
    layers.remove(at: sourceIndexPath.row)
    layers.insert(movedLayer, at: destinationIndexPath.row)
    
    for (index, layer) in layers.enumerated() {
      layer.groupIndex = Int16(index) // reset indexes on group layers
    }
    
    layerManager.saveLayers()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return layers.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LayerCell
    
    cell.update(_layer: layers[indexPath.row], layerManager: layerManager, mapViewController: mapViewController)
    
    let labelRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tableViewLabelClick))
    cell.isUserInteractionEnabled = true
    cell.addGestureRecognizer(labelRecognizer)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let layer = layers[indexPath.row]
      layers.remove(at: indexPath.row)

      self.layerManager.removeLayer(layer: layer)
    }
  }
  
  @objc func tableViewLabelClick(sender : UITapGestureRecognizer){
    let tapLocation = sender.location(in: tableView)
    let indexPath = self.tableView.indexPathForRow(at: tapLocation)
    let position = indexPath?.row ?? 0
  
    let layer = layers[position]
    
    if(layer.enabled) {
      layerManager.disableLayer(layer: layer)
    }
    else {
      layerManager.enableLayer(layer: layer, mutuallyExclusive: true)
    }
    
    UISelectionFeedbackGenerator().selectionChanged()
  }
}
