import Foundation
import UIKit
import CoreData

import Mapbox

var cellReuseCache: [String: LayerCell] = [:]

class Section: UIStackView {
  let group: LayerGroup
  let layerSelectConfig: LayerSelectConfig
  
  let layerCanDrop: ((Layer) -> Bool)?
  let layerDidDrag: ((Layer) -> ())?
  let layerDidDrop: ((Layer) -> ())?

  let tableView = SectionTableView()
  
  unowned let scrollView: LayerSelectView

  var layers: [Layer]
  var ready = false
  var updating = false
  var missedUpdate = false
  
  var normallyCollapsed: Bool
  
  var sectionOpenConstraint: NSLayoutConstraint!
  var sectionCollapsedConstraint: NSLayoutConstraint!
  var sectionHiddenConstraint: NSLayoutConstraint!
  
  var openState: SectionOpenState = .hidden {
    didSet {
      updateState()
    }
  }
  
  var showAllDisabled: Bool = false {
    didSet {
      update()
    }
  }
  
  var numberDisabled: Int {
    get {layers.filter({!$0.enabled}).count}
  }
  
  var numberDisabledHidden: Int {
    get {
      numberDisabled > 1
        ? numberDisabled - 1
        : 0
    }
  }
  
  lazy var spacerView: UIView = {
    let view = UIView()
    
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()
  
  init(
    group: LayerGroup,
    layerSelectConfig: LayerSelectConfig,
    scrollView: LayerSelectView,
    normallyCollapsed: Bool = false,
    layerCanDrop: ((Layer) -> Bool)? = nil,
    layerDidDrag: ((Layer) -> ())? = nil,
    layerDidDrop: ((Layer) -> ())? = nil
  ){
    self.group = group
    self.layerSelectConfig = layerSelectConfig
    
    self.scrollView = scrollView
    self.normallyCollapsed = normallyCollapsed
    
    self.layers = group.getLayers()
    
    self.layerCanDrop = layerCanDrop
    self.layerDidDrag = layerDidDrag
    self.layerDidDrop = layerDidDrop
    
    super.init(frame: CGRect())
        
    axis = .vertical
    alignment = .leading
    distribution = .fill
    spacing = 10
    
    let label = SectionLabel()
    label.text = group.name.uppercased()
    label.accessibilityLabel = "Toggle" + group.name + " Group"
    label.accessibilityTraits = .header
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
    tableView.dragDelegate = self
    tableView.dropDelegate = self
    tableView.dragInteractionEnabled = true
    
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
    
    scrollView.multicastScrollViewDidScrollDelegate.add(delegate: self)
    
    if(layers.count == 0){
      updateState()
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
      self.update()
    }
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
    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // needs more delay
//      self.scrollView.heightDidChange()
//    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if((!ready || missedUpdate) && !updating) {
      update(fromScroll: true)
    }
  }
  
  func update(fromScroll: Bool = false) {
    if(!isVisible()) {
      if(!fromScroll){
        missedUpdate = true
      }
      return
    }
    
    
    updating = true
    missedUpdate = false

    
    DispatchQueue.global(qos: .userInteractive).async {[self] in
      self.layers = SettingsManager.shared.showDisabledLayers.value
        ? group.getLayers().sorted(by: LayerManager.shared.layerSortingFunction)
        : group.getLayers().filter({$0.enabled}).sorted(by: LayerManager.shared.layerSortingFunction)
      self.ready = true
      
      DispatchQueue.main.async {
        if(self.layers.count > 0) {
          if(openState == .hidden) {
            openState =  normallyCollapsed ? .collapsed : .open
          }
        } else {
          openState = .hidden
        }
        
        tableView.reloadData()
        self.updating = false
      }
    }
  }
  
   @discardableResult func toggleLayer(layer: Layer, mutuallyExclusive: Bool) -> Bool {
    var result: Bool
    
    if(layer.visible) {
      result = LayerManager.shared.hide(layer: layer, mutuallyExclusive: mutuallyExclusive)
    }
    else {
      result = LayerManager.shared.show(layer: layer, mutuallyExclusive: mutuallyExclusive)
    }
    
    if(result) {
      UISelectionFeedbackGenerator().selectionChanged()
    }
    
    return result
  }
  
  func cementLayerIndicies(){
    for (index, layer) in layers.enumerated() {
      layer.groupIndex = Int16(index) // reset indexes on group layers
    }
    
    LayerManager.shared.save()
  }
  
  func remove(layer: Layer, indexPath: IndexPath){
    let layerName = layer.name
    self.layers.remove(at: indexPath.row)
    LayerManager.shared.remove(layer: layer)
  
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    HUDManager.shared.displayMessage(message: .layerDeleted(layerName))
  }
  
  @objc func tableViewLabelClick(sender : UITapGestureRecognizer){
    let tapLocation = sender.location(in: tableView)
    let indexPath = self.tableView.indexPathForRow(at: tapLocation)
    let position = indexPath?.row ?? 0
  
    let layer = layers[position]
    
    if(indexPath?.row == layers.count - numberDisabled && !layer.visible) {
      showAllDisabled = !showAllDisabled
    } else {
      toggleLayer(layer: layer, mutuallyExclusive: layerSelectConfig.mutuallyExclusive)
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct DragDropContainer {
  let layer: Layer
  let layerDidDrag: ((Layer) -> ())?
}

extension Section: UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate {  
  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    let dragItem = UIDragItem(itemProvider: NSItemProvider())
    dragItem.localObject = DragDropContainer(layer: layers[indexPath.row], layerDidDrag: layerDidDrag)
    
    return [dragItem]
  }
  
  func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    let indexPath = coordinator.destinationIndexPath ?? IndexPath(row: 0, section: 0)

    guard let container = coordinator.session.items.first?.localObject as? DragDropContainer else { return }
    
    let layer = container.layer
    let sourceLayerDidDrag = container.layerDidDrag
    
    sourceLayerDidDrag?(layer)

    if(layerDidDrop != nil) {
      layerDidDrop!(layer)

      LayerManager.shared.save()
    } else {
      layer.group = group.id
      
      self.layers.insert(layer, at: indexPath.row)
      self.cementLayerIndicies()
    }
  }
  
  func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
    if let container = session.items.first?.localObject as? DragDropContainer {
      return layerCanDrop?(container.layer) ?? true
    }
    
    return false
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return layerSelectConfig.reorderLayers
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let movedLayer = layers[sourceIndexPath.row]
    layers.remove(at: sourceIndexPath.row)
    layers.insert(movedLayer, at: destinationIndexPath.row)
    
    cementLayerIndicies()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if(showAllDisabled) {return layers.count}
    
    return numberDisabled == 0
      ? layers.count
      : layers.count - (numberDisabled - 1)
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let _layer = layers[indexPath.row]
    let cacheKey = _layer.id + "." + group.id

    let cell = cellReuseCache[cacheKey] ?? { // UITableView's dequeue is dumb and won't reuse the same cell for the same layer consistantly
      let newCell = LayerCell()
      cellReuseCache[cacheKey] = newCell
      
      return newCell
    }()
    
    if(!ready) {
      return cell
    }
    
    var accessory: LayerCellAccessory

    if(_layer.enabled || _layer.visible || numberDisabledHidden == 0){
      accessory = .normal
    } else if(indexPath.row == layers.count - numberDisabled) {
      accessory = showAllDisabled ? .collapse : .plus(numberDisabledHidden)
    } else {
      accessory = .normal
    }

    cell.update(_layer: _layer, layerSelectConfig: layerSelectConfig, scrollView: scrollView, accessory: accessory)
    
    let cellGR = UITapGestureRecognizer(target: self, action: #selector(self.tableViewLabelClick))
    cell.isUserInteractionEnabled = true
    cell.addGestureRecognizer(cellGR)
    
    return cell
  }
    
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if(!layerSelectConfig.layerContextActions) {return}
    
    let layer = self.layers[indexPath.row]
    
    if editingStyle == .delete {
      self.remove(layer: layer, indexPath: indexPath)
    }
  }
  
  func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    if(!layerSelectConfig.layerContextActions) {
      return nil
    }
    
    let layer = self.layers[indexPath.row]
    
    let action = UIContextualAction(style: .normal, title: nil) {(action, view, completionHandler) in
      let result = self.toggleLayer(layer: layer, mutuallyExclusive: self.layerSelectConfig.mutuallyExclusive)
      if result {
        MapViewController.shared.lsfpc.dismiss(animated: true, completion: nil)
      }
      
      completionHandler(result)
    }
    
    action.image = UIImage(systemName: layer.visible ? "eye.slash" : "eye")
    action.backgroundColor = layer.visible ? .systemOrange : .systemBlue
    let configuration = UISwipeActionsConfiguration(actions: [action])
    return configuration
  }
}

enum SectionOpenState {
  case open
  case collapsed
  case hidden
}
