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
      
      let editsSupported = [layer.style.supportsColour, layer.style.supportsOpacity]
      
      let colourableLayers = layer.style.interfacedLayers.filter({$0.capabilities.contains(.colour)})
      let opacitySupportingLayers = layer.style.interfacedLayers.filter({$0.capabilities.contains(.opacity)})
      
      let singleColourMenu = UIAction( // single colour in style
        title: "Set Colour",
        image: UIImage(systemName: "eyedropper")){ _ in
          let colourableLayer = colourableLayers.first!
          let colour = colourableLayer.colour ?? .randomSystemColor().withAlphaComponent(CGFloat(colourableLayer.opacity ?? 1))
          self.layerSelectConfig.layerEditDelegate?.requestLayerColourPicker(colour, supportsAlpha: colourableLayer.capabilities.contains(.opacity)){newColour in
            let options = colourableLayers.map({$0.setting(.colour, to: newColour).setting(.opacity, to: nil)})
            layer.style = layer.style.with(options)
            LayerManager.shared.save()
          }
      }
            
      let manyColoursMenu = UIMenu( // many colours in style
        title: "Set Colour",
        image: UIImage(systemName: "eyedropper"),
        children: {
          var children: [UIMenuElement] = colourableLayers.map({colourableLayer in
          let colour = colourableLayer.colour ?? .randomSystemColor().withAlphaComponent(CGFloat(colourableLayer.opacity ?? 1))
            return UIAction(
              title: colourableLayer.id,
              image: UIImage(systemName: "circle.fill")?.withTintColor(colour).withRenderingMode(.alwaysOriginal)) { _ in
                self.layerSelectConfig.layerEditDelegate?.requestLayerColourPicker(colour, supportsAlpha: colourableLayer.capabilities.contains(.opacity)){newColour in
                  layer.style = layer.style.with([colourableLayer.setting(.colour, to: newColour).setting(.opacity, to: nil)])
                  LayerManager.shared.save()
                }
            }
          })
          
          let allMenu = UIAction(
            title: "All",
            image: UIImage(systemName: "circles.hexagongrid.fill")){ _ in
              let colourableLayer = colourableLayers.first!
              let colour = colourableLayer.colour ?? .randomSystemColor().withAlphaComponent(CGFloat(colourableLayer.opacity ?? 1))
              self.layerSelectConfig.layerEditDelegate?.requestLayerColourPicker(colour, supportsAlpha: colourableLayer.capabilities.contains(.opacity)){newColour in
                let options = colourableLayers.map({$0.setting(.colour, to: newColour).setting(.opacity, to: nil)})
                layer.style = layer.style.with(options)
                LayerManager.shared.save()
              }
          }
          
          children.append(allMenu)
          
          return children
        }()
      )
      
      let setColourMenu = (colourableLayers.count == 1 || colourableLayers.allSatisfy({$0.colour == colourableLayers.first?.colour})) ? singleColourMenu : manyColoursMenu
      
      let generateOpacityMenu = {(opacitySupportingLayers: [Style.InterfacedLayer]) -> ([UIMenuElement]) in
        [100, 75, 50, 25, 10].compactMap({percent in
          let opacity = Double(percent) / 100
          let selected = (opacitySupportingLayers.count == 1 || opacitySupportingLayers.allSatisfy({$0.opacity == opacitySupportingLayers.first?.opacity})) && (opacity == opacitySupportingLayers.first?.opacity )

          return UIAction(
            title: String(format: "%d%%", percent),
            image: UIImage(systemName: "square\(opacity == 0 ? "" : ".fill")")?.withTintColor(iconColour.withAlphaComponent(opacity == 0 ? 1 : CGFloat(opacity))).withRenderingMode(.alwaysOriginal),
            state: selected ? .on : .off) { _ in
              layer.style = layer.style.with(opacitySupportingLayers.map({$0.setting(.opacity, to: opacity)}))
              LayerManager.shared.save()
          }
        })
      }
      
      let singleOpacityMenu = UIMenu( // single opacity in style
        title: "Set Opacity",
        image: UIImage(systemName: "slider.horizontal.below.rectangle"),
        children: generateOpacityMenu(opacitySupportingLayers)
      )
      
      let manyOpacitiesMenu = UIMenu( // many opacities in style
        title: "Set Opacity",
        image: UIImage(systemName: "slider.horizontal.below.rectangle"),
        children: {
          var children: [UIMenuElement] = opacitySupportingLayers.map({opacitySupportingLayer in
            let colour = opacitySupportingLayer.colour ?? iconColour.withAlphaComponent(CGFloat(opacitySupportingLayer.opacity ?? 1))
            return UIMenu(
              title: opacitySupportingLayer.id,
              image: UIImage(systemName: "square.fill")?.withTintColor(colour).withRenderingMode(.alwaysOriginal),
              children: generateOpacityMenu([opacitySupportingLayer])
            )
          })
          
          let allMenu = UIMenu(
            title: "All",
            image: UIImage(systemName: "square.grid.3x3.fill"),
            children: generateOpacityMenu(opacitySupportingLayers)
          )
          
          children.append(allMenu)
          
          return children
        }()
      )
      
      let setOpacityMenu = (opacitySupportingLayers.count == 1 || opacitySupportingLayers.allSatisfy({$0.opacity == opacitySupportingLayers.first?.opacity})) ? singleOpacityMenu : manyOpacitiesMenu
      
      topChildren.append(editsSupported.contains(true) ? UIMenu(
        title: "Edit",
        image: UIImage(systemName: "slider.horizontal.3"),
        children: [
          layer.style.supportsOpacity ? setOpacityMenu : nil,
          layer.style.supportsColour ? setColourMenu : nil,
          UIAction(
            title: "Full Edit",
            image: UIImage(systemName: "slider.horizontal.3")) { _ in
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
        image: UIImage(systemName: "plus.square.on.square")) { _ in
          self.layerSelectConfig.layerEditDelegate?.requestLayerEdit(.duplicate(layer))
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

      moreChildren.append(UIMenu(
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
}