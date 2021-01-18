import Foundation
import UIKit
import CoreData

import Mapbox

class Section: UIStackView {
  let group: LayerGroup
  let layerManager: LayerManager
  var layers: [Layer]
  let tableView = SectionTableView()
  
  init(group: LayerGroup, layerManager: LayerManager){
    self.group = group
    self.layerManager = layerManager
    self.layers = layerManager.getLayers(layerGroup: group)!.reversed()
    
    super.init(frame: CGRect())
    
    layerManager.multicastLayersHaveChangedDelegate.add(delegate: self)
    
    axis = .vertical
    alignment = .leading
    distribution = .fill
    spacing = 10
//  backgroundColor = UIColor.blue
    
    let label = SectionLabel(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
    label.text = group.name.uppercased()
    label.font = UIFont.boldSystemFont(ofSize: 12)
    label.textColor = group.colour == UIColor.systemYellow ? .black : .white
    
    label.backgroundColor = group.colour
    label.layer.cornerRadius = 5
    label.layer.cornerCurve = .continuous
    label.layer.masksToBounds = true
    
    addArrangedSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    
    tableView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.75)
    tableView.dataSource = self
//    tableView.isEditing = true
    tableView.isScrollEnabled = false
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.register(LayerCell.self, forCellReuseIdentifier: "cell")
    
    
    addArrangedSubview(tableView)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func layersHaveChanged() {
    tableView.reloadData()
  }
}

extension Section: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return layers.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LayerCell
    
    cell.update(_layer: layers[indexPath.row], layerManager: layerManager)
    
    let labelRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tableViewLabelClick))
    cell.isUserInteractionEnabled = true
    cell.addGestureRecognizer(labelRecognizer)
    
    return cell
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
      layerManager.enableLayer(layer: layer)
    }
        
//    tableView.reloadData()
  }
  
//  func tableView(_ tableView: UITableView, didSelectRowAtindexPath indexPath: IndexPath) {
//      print(indexPath.row)
//  }
  
//  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//      return true // Yes, the table view can be reordered
//  }
//  
//  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//      let movedObject = layers[sourceIndexPath.row]
//      layers.remove(at: sourceIndexPath.row)
//      layers.insert(movedObject, at: destinationIndexPath.row)
//  }
}
