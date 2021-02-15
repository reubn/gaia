import Foundation
import UIKit
import CoreData

import Mapbox

class Section: UIStackView {
  let group: LayerGroup
  let layerSelectConfig: LayerSelectConfig
  let layerManager: LayerManager
  let mapViewController: MapViewController
  let tableView = SectionTableView()
  
  unowned let scrollView: LayerSelectView

  var layers: [Layer]
  
  var sectionOpenConstraint: NSLayoutConstraint!
  var sectionCollapsedConstraint: NSLayoutConstraint!
  var sectionHiddenConstraint: NSLayoutConstraint!
  
  var openState: SectionOpenState = .hidden {
    didSet {
      updateState()
    }
  }
  
  lazy var spacerView: UIView = {
    let view = UIView()
    
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()
  
  init(group: LayerGroup, layerSelectConfig: LayerSelectConfig, layerManager: LayerManager, mapViewController: MapViewController, scrollView: LayerSelectView){
    self.group = group
    self.layerSelectConfig = layerSelectConfig
    self.layerManager = layerManager
    self.mapViewController = mapViewController
    self.scrollView = scrollView
    self.layers = layerManager.getLayers(layerGroup: group).reversed()
    
    super.init(frame: CGRect())
        
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
    
    let labelTapGR = UITapGestureRecognizer(target: self, action: #selector(self.toggleCollapse))
    label.isUserInteractionEnabled = true
    label.addGestureRecognizer(labelTapGR)
    
    tableView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.75)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.dragDelegate = self // empty drag, drop delegate methods needed to enable moveRowAt... bug?
    tableView.dropDelegate = self // empty drag, drop delegate methods needed to enable moveRowAt... bug?
    tableView.dragInteractionEnabled = layerSelectConfig.reorderLayers
    
    tableView.isScrollEnabled = false
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.register(LayerCell.self, forCellReuseIdentifier: "cell")
    
    addArrangedSubview(tableView)
    
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    addArrangedSubview(spacerView)
    
    sectionOpenConstraint = spacerView.heightAnchor.constraint(equalToConstant: 20)
    sectionCollapsedConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
    sectionHiddenConstraint = heightAnchor.constraint(equalToConstant: 0)
    
    update()
  }
  
  @objc func toggleCollapse(){
    switch openState {
      case .open:
        openState = .collapsed
      case .collapsed:
        openState = .open
      case .hidden: break
    }
  }
  
  func updateState(){
    switch openState {
      case .open:
        sectionOpenConstraint.isActive = true
        sectionCollapsedConstraint.isActive = false
        sectionHiddenConstraint.isActive = false
      case .collapsed:
        sectionOpenConstraint.isActive = false
        sectionCollapsedConstraint.isActive = true
        sectionHiddenConstraint.isActive = false
      case .hidden:
        sectionOpenConstraint.isActive = false
        sectionCollapsedConstraint.isActive = false
        sectionHiddenConstraint.isActive = true
    }
  }
  
  func update() {
    self.layers = layerManager.getLayers(layerGroup: group).reversed()
    
    if(self.layers.count > 0) {
      if(openState == .hidden) {
        openState = .open
      }
    } else {
      openState = .hidden
    }
    
    tableView.reloadData()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension Section: UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate {
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
    
    cell.update(_layer: layers[indexPath.row], layerSelectConfig: layerSelectConfig, layerManager: layerManager, mapViewController: mapViewController, scrollView: scrollView)
    
    let cellGR = UITapGestureRecognizer(target: self, action: #selector(self.tableViewLabelClick))
    cell.isUserInteractionEnabled = true
    cell.addGestureRecognizer(cellGR)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    if(!layerSelectConfig.layerContextActions) {return nil}
    
    let layer = self.layers[indexPath.row]
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){actions -> UIMenu? in
      
      var children: [UIAction] = []
 
      children.append(UIAction(
        title: layer.enabled ? "Hide" : "Show",
        image: UIImage(systemName: layer.enabled ? "eye.slash" : "eye")) { _ in
        self.toggleLayer(layer: layer, mutuallyExclusive: false)
      })
      
      children.append(UIAction(
        title: "Isolate",
        image: UIImage(systemName: "square.3.stack.3d.middle.fill")) { _ in
          self.layerManager.filterLayers {
            $0 == layer
          }
      })
      
      children.append(UIAction(
        title: "Edit",
        image: UIImage(systemName: "pencil")) { _ in
          self.layerSelectConfig.layerEditDelegate?.layerEditWasRequested(layer: layer)
      })
      
      children.append(UIAction(
        title: "Share",
        image: UIImage(systemName: "square.and.arrow.up")) { _ in
          do {
            let encoder = JSONEncoder()
            
            let json = try encoder.encode([LayerDefinition(layer: layer)])
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(layer.id).appendingPathExtension("json")

            try json.write(to: temporaryFileURL, options: .atomic)
            
            let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = tableView
            self.mapViewController.lsfpc.present(activityViewController, animated: true, completion: nil)
            
          } catch {
            print(error)
        }
      })
      
      let delete = UIAction(
        title: "Delete",
        image: UIImage(systemName: "trash"),
        attributes: .destructive) { _ in
          self.layers.remove(at: indexPath.row)
          self.layerManager.removeLayer(layer: layer)
      }
      
      children.append(delete)
      
      return UIMenu(title: "", children: children)
    }
  }
  
  func toggleLayer(layer: Layer, mutuallyExclusive: Bool){
    if(layer.enabled) {
      layerManager.disableLayer(layer: layer)
    }
    else {
      layerManager.enableLayer(layer: layer, mutuallyExclusive: mutuallyExclusive)
    }
    
    UISelectionFeedbackGenerator().selectionChanged()
  }
  
  @objc func tableViewLabelClick(sender : UITapGestureRecognizer){
    let tapLocation = sender.location(in: tableView)
    let indexPath = self.tableView.indexPathForRow(at: tapLocation)
    let position = indexPath?.row ?? 0
  
    let layer = layers[position]
    
    toggleLayer(layer: layer, mutuallyExclusive: layerSelectConfig.mutuallyExclusive)
  }
}

enum SectionOpenState {
  case open
  case collapsed
  case hidden
}
