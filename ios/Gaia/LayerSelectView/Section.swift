import Foundation
import UIKit
import CoreData

import Mapbox

class Section: UIStackView {
  let group: LayerGroup
  let layerSelectConfig: LayerSelectConfig
  
  let layerCanDrop: ((Layer) -> Bool)?
  let layerDidDrag: ((Layer) -> ())?
  let layerDidDrop: ((Layer) -> ())?

  let tableView = SectionTableView()
  
  var cellReuseCache: [String: LayerCell] = [:]
  
  unowned let scrollView: LayerSelectView

  var layers: [Layer]
  
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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // needs more delay
      self.scrollView.heightDidChange()
    }
  }
  
  func update() {
    self.layers = layerSelectConfig.showDisabled
      ? group.getLayers()
      : group.getLayers().filter({$0.enabled})
    
    if(self.layers.count > 0) {
      if(openState == .hidden) {
        openState =  normallyCollapsed ? .collapsed : .open
      }
    } else {
      openState = .hidden
    }
    
    tableView.reloadData()
  }
  
  func toggleLayer(layer: Layer, mutuallyExclusive: Bool){
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
    let cell = cellReuseCache[_layer.id] ?? { // UITableView's dequeue is dumb and won't reuse the same cell for the same layer consistantly
      let newCell = LayerCell()
      cellReuseCache[_layer.id] = newCell
      
      return newCell
    }()
    
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
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    if(!layerSelectConfig.layerContextActions) {return nil}
    
    let layer = self.layers[indexPath.row]
    let iconColour: UIColor = self.traitCollection.userInterfaceStyle == .light ? .black : .white
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){actions -> UIMenu? in
      var topChildren: [UIMenuElement] = []
      var moreChildren: [UIMenuElement] = []
 
      topChildren.append(UIAction(
        title: layer.visible ? "Hide" : "Show",
        image: UIImage(systemName: layer.visible ? "eye.slash" : "eye")) { _ in
          self.toggleLayer(layer: layer, mutuallyExclusive: false)
      })
      
      if(layer.enabled) {
        topChildren.append(UIAction(
          title: layer.pinned ? "Unpin" : "Pin",
          image: UIImage(systemName: layer.pinned ? "pin.slash.fill" : "pin.fill")) { _ in
          layer.pinned = !layer.pinned
          
          LayerManager.shared.save()
        })
      }
      
      let editsSupported = [layer.style.supportsColour, layer.style.supportsOpacity]
      
      topChildren.append(editsSupported.contains(true) ? UIMenu(
        title: "Edit",
        image: UIImage(systemName: "slider.horizontal.3"),
        children: [
          layer.style.supportsOpacity ? UIMenu(
            title: "Set Opacity",
            image: UIImage(systemName: "checkerboard.rectangle"),
            children: [100, 75, 50, 25, 10].compactMap({percent in
              let opacity = Double(percent) / 100
              let selected = opacity == layer.style.opacity

              return UIAction(
                title: String(format: "%d%%", percent),
                image: UIImage(systemName: selected ? "checkmark.square.fill" : "square\(opacity == 0 ? "" : ".fill")")?.withTintColor(iconColour).with(alpha: opacity == 0 ? 1 : CGFloat(opacity)),
                attributes: selected ? .disabled : []) { _ in
                layer.style = layer.style.with(opacity: opacity)
                LayerManager.shared.save()
              }
            })
          ) : nil,
          layer.style.supportsColour ? UIAction(
            title: "Set Color",
            image: UIImage(systemName: "eyedropper.full")){ _ in
              
            self.layerSelectConfig.layerEditDelegate?.requestLayerColourPicker(layer, supportsAlpha: layer.style.supportsOpacity){colour in
              layer.style = layer.style.with(colour: colour.withAlphaComponent(1))
              
              if let alpha = colour.components?.alpha,
                 alpha != 1 {
                layer.style = layer.style.with(opacity: Double(alpha).rounded(toDecimalPlaces: 2))
              }
              
              LayerManager.shared.save()
            }
          } : nil,
          UIAction(
            title: "Edit Layer",
            image: UIImage(systemName: "chevron.left.slash.chevron.right")) { _ in
              self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.edit(layer))
          }
        ].compactMap{$0}
        ) : UIAction(
              title: "Edit",
              image: UIImage(systemName: "slider.horizontal.3")){ _ in
                self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.edit(layer))
      })
      
      // More Submenu
      moreChildren.append(UIAction(
        title: "Isolate",
        image: UIImage(systemName: "square.3.stack.3d.middle.fill")) { _ in
          LayerManager.shared.filter {
            $0 == layer
          }
      })
      
      moreChildren.append(UIAction(
        title: "Duplicate",
        image: UIImage(systemName: "plus.square.fill.on.square.fill")) { _ in
          self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.duplicate(layer))
      })
      
      moreChildren.append(UIMenu(
        title: "Move to...",
        image: UIImage(systemName: "folder"),
        children: LayerManager.shared.groupIds.map({id in
          let group = LayerManager.shared.groups.first(where: {$0.id == id})!
          
          return UIAction(
            title: group.name,
            image: UIImage(systemName: group.icon ?? "\(group.name.first!.lowercased()).square.fill"),
            state: layer.group == group.id ? .on : .off) { _ in
              layer.group = group.id
              LayerManager.shared.save()
          }
        })
      ))

      moreChildren.append(UIAction(
        title: "Share",
        image: UIImage(systemName: "square.and.arrow.up")) { _ in
          do {
            let encoder = JSONEncoder()

            var layerDefinition = LayerDefinition(layer: layer)
            layerDefinition.user = nil

            let json = try encoder.encode([layerDefinition])

            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(layer.id).appendingPathExtension("json")

            try json.write(to: temporaryFileURL, options: .atomic)

            let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = tableView
            MapViewController.shared.lsfpc.present(activityViewController, animated: true, completion: nil)

          } catch {
            print(error)
        }
      })
      
      moreChildren.insert(UIAction(
        title: layer.enabled ? "Disable" : "Enable",
        image: UIImage(systemName: layer.enabled ? "square.slash.fill" : "checkmark.square.fill"),
        attributes: layer.enabled ? .destructive : []) { _ in
          layer.enabled = !layer.enabled

          if(!layer.enabled){
            layer.pinned = false
            layer.visible = false
          }

          LayerManager.shared.save()
      }, at: layer.enabled ? moreChildren.endIndex : moreChildren.startIndex)
      
      topChildren.append(UIMenu(
        title: "More",
        image: UIImage(systemName: "ellipsis"),
        children: moreChildren
      ))
      
      let delete = UIAction(
        title: "Delete",
        image: UIImage(systemName: "trash"),
        attributes: .destructive) { _ in
          self.remove(layer: layer, indexPath: indexPath)
      }
      
      topChildren.append(delete)
      
      return UIMenu(title: layer.attribution ?? "", children: topChildren)
    }
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if(!layerSelectConfig.layerContextActions) {return}
    
    let layer = self.layers[indexPath.row]
    
    if editingStyle == .delete {
      self.remove(layer: layer, indexPath: indexPath)
    }
  }
}

enum SectionOpenState {
  case open
  case collapsed
  case hidden
}
