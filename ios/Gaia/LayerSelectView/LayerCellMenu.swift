import Foundation
import UIKit

extension Section {
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    if(!layerSelectConfig.layerContextActions) {return nil}
    
    let layer = self.layers[indexPath.row]
    let iconColour: UIColor = self.traitCollection.userInterfaceStyle == .light ? .black : .white
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){actions -> UIMenu? in
      var topChildren: [UIMenuElement] = []
      var moreChildren: [UIMenuElement] = []
      
      let moveToMenu = UIMenu(
        title: "Move to...",
        image: UIImage(systemName: "folder"),
        children: LayerManager.shared.groupIds.map({id in
          let group = LayerManager.shared.groups.first(where: {$0.id == id})!
          
          return UIAction(
            title: group.name,
            image: UIImage(systemName: group.icon ?? "\(group.name.first!.lowercased()).square"),
            state: layer.group == group.id ? .on : .off) { _ in
            layer.group = group.id
            LayerManager.shared.save()
          }
        })
      )
      
      if(!layer.enabled) {
        topChildren.append(UIAction(
          title: "Enable",
          image: UIImage(systemName: "checkmark.square.fill")) { _ in
            layer.enabled = true

            LayerManager.shared.save()
        })
      }
 
      topChildren.append(UIAction(
        title: layer.visible ? "Hide" : "Show",
        image: UIImage(systemName: layer.visible ? "eye.slash" : "eye")) { _ in
          self.toggleLayer(layer: layer, mutuallyExclusive: false)
      })
            
      if(layer.enabled) {
        topChildren.append(UIAction(
          title: layer.pinned ? "Unpin" : "Pin",
          image: UIImage(systemName: layer.pinned ? "pin.slash" : "pin")) { _ in
          layer.pinned = !layer.pinned
          
          LayerManager.shared.save()
        })
      }
      
      if(layer.group == "") {
        topChildren.append(moveToMenu)
      }
      
      topChildren.append(editMenu())
      
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
        image: UIImage(systemName: "plus.square.on.square")) { _ in
          self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.duplicate(layer))
      })
      
      moreChildren.append(UIAction(
        title: layer.quickToggle ? "Disable Quick Toggle" : "Enable Quick Toggle",
        image: UIImage(systemName: layer.quickToggle ? "bolt.slash.fill" : "bolt.fill")) { _ in
          layer.quickToggle = !layer.quickToggle
          LayerManager.shared.save()
      })
      
      moreChildren.append(UIMenu(
        title: "Dark Mode",
        image: UIImage(systemName: "moon"),
        children: ["dark", "light"].compactMap({option in
          UIAction(
            title: option == "dark" ? "Dark Mode" : "Light Mode",
            image: UIImage(systemName: option == "dark" ? "moon" : "sun.max"),
            state: layer.overrideUIMode == option ? .on : .off) { _ in
            if(layer.overrideUIMode == option){
              layer.overrideUIMode = nil // deselect current selection
            } else {
              layer.overrideUIMode = option
            }
            LayerManager.shared.save()
          }
        })
      ))

      moreChildren.append(moveToMenu)

      moreChildren.append(UIAction(
        title: "Share",
        image: UIImage(systemName: "square.and.arrow.up")) { _ in
          do {
            let encoder = JSONEncoder()

            var layerDefinition = LayerDefinition(layer: layer)
            layerDefinition.user = nil

            let json = try encoder.encode([layerDefinition])

            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(layer.name).appendingPathExtension("json")

            try json.write(to: temporaryFileURL, options: .atomic)

            let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = tableView
            MapViewController.shared.lsfpc.present(activityViewController, animated: true, completion: nil)

          } catch {
            print(error)
        }
      })
      
      if(layer.enabled) {
        moreChildren.append(UIAction(
          title: "Disable",
          image: UIImage(systemName: "square.slash.fill"),
          attributes: .destructive) { _ in
            layer.enabled = false
            layer.pinned = false
            layer.visible = false

            LayerManager.shared.save()
        })
      }
      
      topChildren.append(UIMenu(
        title: "More",
        image: UIImage(systemName: "ellipsis"),
        children: moreChildren
      ))
      
      topChildren.append(UIMenu(
        title: "Delete",
        image: UIImage(systemName: "trash"),
        options: .destructive,
        children: [UIAction(
          title: "Confirm",
          image: UIImage(systemName: "trash"),
          attributes: .destructive) { _ in
            self.remove(layer: layer, indexPath: indexPath)
        }]
      ))

      func editMenu() -> UIMenuElement {
        let interfacedLayers = layer.style.interfacedLayers
        let containsEditableLayers = interfacedLayers.contains(where: {!$0.capabilities.isEmpty && $0.capabilities.isSubset(of: Style.InterfacedLayer.Capability.allCases)})
        
        guard containsEditableLayers else {
          return UIAction(
            title: "Edit",
            image: UIImage(systemName: "slider.horizontal.3")){_ in
              self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.edit(layer))
          }
        }
        
        let fullEdit = UIMenu(
          title: "",
          options: .displayInline,
          children: [
            UIAction(
              title: "Edit JSON",
              image: UIImage(systemName: "slider.horizontal.3")) { _ in
              self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.edit(layer))
            }
          ]
        )
        
        let editLayersChildren = interfacedLayers.count == 1
          ? [editLayerItems(interfacedLayer: interfacedLayers.first!, single: true), fullEdit]
          : [fullEdit] + editLayersItems(interfacedLayers: interfacedLayers)
        
        return UIMenu(
          title: "Edit",
          image: UIImage(systemName: "slider.horizontal.3"),
          children: editLayersChildren
        )
      }
      
      func editLayersItems(interfacedLayers: [Style.InterfacedLayer]) -> [UIMenuElement] {
        interfacedLayers.map({editLayerItems(interfacedLayer: $0)})
      }

      func editLayerItems(interfacedLayer: Style.InterfacedLayer, single: Bool = false) -> UIMenuElement {
        if interfacedLayer.capabilities.contains(.colour) {
          return setColourElement(interfacedLayer: interfacedLayer, title: single ? "Edit Colour" : nil)
        }
        
        if interfacedLayer.capabilities.contains(.opacity) {
          return setOpacityElement(interfacedLayer: interfacedLayer, title: single ? "Edit Opacity" : nil)
        }
        
        return UIAction(
          title: interfacedLayer.id,
          image: UIImage(systemName: "slash.circle.fill"),
          attributes: .disabled,
          handler: {_ in}
        )
      }

      func setColourElement(interfacedLayer: Style.InterfacedLayer, title: String? = nil) -> UIMenuElement {
        let colour = interfacedLayer.colour ?? iconColour.withAlphaComponent(interfacedLayer.opacity ?? 1)
        let iconName = interfacedLayer.colourIsExpression
          ? "exclamationmark.circle.fill"
          : interfacedLayer.colour != nil
            ? "circle.fill"
            : "slash.circle.fill"
        let iconColour = colour.withAlphaComponent(1)
        let icon = UIImage(systemName: iconName)?.withTintColor(iconColour).withRenderingMode(.alwaysOriginal)
        let title = title ?? interfacedLayer.id
        
        let handler: UIActionHandler = {_ in
          self.layerSelectConfig.layerEditDelegate?.requestLayerColourPicker(colour, supportsAlpha: true){newColour in
            let options = [interfacedLayer.setting(.colour, to: newColour).setting(.opacity, to: nil)]
            layer.style = layer.style.with(options)
            LayerManager.shared.save()
          }
        }
        
        return interfacedLayer.colourIsExpression
          ? UIMenu(
            title: title,
            image: icon,
            children: [
              UIAction(
                title: "Back",
                image: UIImage(systemName: "arrow.uturn.backward"),
                handler: {_ in}
              ),
              UIAction(
                title: "Override Expression",
                image: UIImage(systemName: "exclamationmark.circle.fill"),
                attributes: .destructive,
                handler: handler
              )
            ]
          )
          : UIAction(
            title: title,
            image: icon,
            handler: handler
          )
      }
      
      func setOpacityElement(interfacedLayer: Style.InterfacedLayer, title: String? = nil) -> UIMenuElement {
        let iconColour = (interfacedLayer.colour ?? iconColour).withAlphaComponent(interfacedLayer.opacity ?? 1)
        
        let iconName = interfacedLayer.opacityIsExpression
          ? "exclamationmark.square.fill"
          : interfacedLayer.opacity != nil
            ? "square.fill"
            : "square.slash.fill"
        let icon = UIImage(systemName: iconName)?.withTintColor(iconColour).withRenderingMode(.alwaysOriginal)
        let title = title ?? interfacedLayer.id

        return UIMenu(
          title: title,
          image: icon,
          children: (
            interfacedLayer.opacityIsExpression
              ? [
                UIAction(
                  title: "Back",
                  image: UIImage(systemName: "arrow.uturn.backward"),
                  handler: {_ in}
                ),
                UIMenu(
                  title: "Override Expression",
                  image: UIImage(systemName: "exclamationmark.circle.fill"),
                  options: .destructive,
                  children: generateOpacityMenu([interfacedLayer])
                )
              ]
            : generateOpacityMenu([interfacedLayer])
          )
        )
      }
      
      func generateOpacityMenu(_ interfacedLayers: [Style.InterfacedLayer]) -> [UIMenuElement]{
        [100, 75, 50, 25, 10, 0].compactMap({percent in
          let opacity = Double(percent) / 100
          let selected = (interfacedLayers.count == 1 || interfacedLayers.allSatisfy({$0.opacity == interfacedLayers.first?.opacity})) && (opacity == interfacedLayers.first?.opacity )
          
          return UIAction(
            title: String(format: "%d%%", percent),
            image: UIImage(systemName: "square.fill")?.withTintColor(iconColour.withAlphaComponent(opacity)).withRenderingMode(.alwaysOriginal),
            state: selected ? .on : .off) { _ in
            layer.style = layer.style.with(interfacedLayers.map({$0.setting(.opacity, to: opacity)}))
            LayerManager.shared.save()
          }
        })
      }
      
      return UIMenu(title: layer.attribution ?? "", children: topChildren)
    }
  }
}
