import Foundation
import UIKit
import UniformTypeIdentifiers

import Mapbox

class LayerSelectHome: UIView, CoordinatedView, UIDocumentPickerDelegate, LayerEditDelegate, PanelDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  lazy var layerSelectConfig = LayerSelectConfig(
    layerEditDelegate: self
  )
  
  lazy var layerSelectView = LayerSelectView(layerSelectConfig: layerSelectConfig)
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    var results: LayerAcceptanceResults?
    
    if let url = urls.first {
      let data = try? Data(contentsOf: url)
      if(data != nil) {
        results = self.coordinatorView.acceptLayerDefinitions(from: data!)
      }
    }
    
    UINotificationFeedbackGenerator().notificationOccurred(results?.rejected.isEmpty == true ? .success : .error)
    HUDManager.shared.displayMessage(message: results != nil ? .layersResults(results!, importing: true) : .syntaxError)
  }

  init(coordinatorView: LayerSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    
    super.init(frame: CGRect())
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true
    
    addSubview(layerSelectView)
    
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: topAnchor, constant: layer.cornerRadius / 2).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    layerSelectView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
  }
  
  func showShareSheet(_ sender: PanelButton, layers: [Layer]) {
    let layerDefinitions = layers.map {LayerDefinition(layer: $0)}
    
    do {
      let encoder = JSONEncoder()
      
      let json = try encoder.encode(layerDefinitions)
      
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("gaiaLayerDefinitions").appendingPathExtension("json")

      try json.write(to: temporaryFileURL, options: .atomic)
      
      let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
      activityViewController.popoverPresentationController?.sourceView = sender
      MapViewController.shared.lsfpc.present(activityViewController, animated: true, completion: nil)
      
    } catch {
      print(error)
    }
  }

  func viewWillEnter(data: Any?){
    print("enter LSH")
    
    if(MapViewController.shared.lsfpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lsfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Layers"
    coordinatorView.panelViewController.panelButtons = [.share, .new, .dismiss]

    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
    
    newButton.isPulsing = LayerManager.shared.layers.isEmpty
    
    newButton.menu = UIMenu(title: "", children: [
      UIAction(title: "Import from URL", image: UIImage(systemName: "link"), handler: {_ in
        self.coordinatorView.goTo(1)
      }),
      UIAction(title: "Import from File", image: UIImage(systemName: "doc"), handler: {_ in
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.xml], asCopy: true)
        documentPicker.delegate = self
        documentPicker.shouldShowFileExtensions = true

        MapViewController.shared.lsfpc.present(documentPicker, animated: true, completion: nil)
      }),
      UIAction(title: "New from Visible", image: UIImage(systemName: "map"), attributes: LayerManager.shared.compositeStyle.sortedLayers.isEmpty ? [.hidden] : [], handler: {_ in
        let constituentLayers = LayerManager.shared.visibleLayers
        
        let randomSuffix = randomString(length: 6)
        let id = "composite_\(randomSuffix)"
        
        let layerDefinition = LayerDefinition(
          metadata: LayerDefinition.Metadata(
            id: id,
            name: "Composite Layer",
            group: ""
          ),
          style: LayerManager.shared.compositeStyle.toStyle()
        )

        if let result = self.coordinatorView.acceptLayerDefinitions(from: [layerDefinition]),
           result.rejected.isEmpty {
          LayerManager.shared.hide(layers: constituentLayers)
          
          if let resultingLayer = LayerManager.shared.layers.first(where: {$0.id == id}){
            LayerManager.shared.show(layer: resultingLayer, mutuallyExclusive: false)
          }
        }
      }),
      UIAction(title: "New", image: UIImage(systemName: "plus"), handler: {_ in
        self.requestLayerEdit(.new)
      }),
      UIMenu(title: "", options: [.displayInline], children: [
        UIDeferredMenuElement.uncached {[weak self] completion in
          let action = UIAction(title: "Add OpenStreetMap", image: UIImage(systemName: "map"), attributes: LayerManager.shared.layers.isEmpty ? [] : [.hidden], handler: {_ in
            let id = "osm"
            let layerDefinition = LayerDefinition(
              metadata: LayerDefinition.Metadata(
                id: id,
                name: "OpenStreetMap",
                group: "base",
                attribution: "© OpenStreetMap contributors"
              ),
              style: Style(
                sources: [
                  id: [
                    "tiles": [
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                    ],
                    "tileSize": 128,
                    "type": "raster"
                  ]
                ],
                layers: [
                  [
                    "id": id,
                    "paint": [
                      "raster-opacity": 1
                    ],
                    "source": id,
                    "type": "raster"
                  ]
                ]
              )
            )
            
            if let result = self?.coordinatorView.acceptLayerDefinitions(from: [layerDefinition]),
               result.rejected.isEmpty {
              if let resultingLayer = LayerManager.shared.layers.first(where: {$0.id == id}){
                LayerManager.shared.show(layer: resultingLayer, mutuallyExclusive: true)
              }
            }
          })
          
          completion([action])
        }
      ])
    ])
    newButton.adjustsImageWhenHighlighted = false
    newButton.showsMenuAsPrimaryAction = true
  }
  
  func update(data: Any?) {}
  
  func viewWillExit(){
    print("exit LSH")

    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
    
    newButton.menu = nil
    newButton.adjustsImageWhenHighlighted = true
    newButton.showsMenuAsPrimaryAction = false
  }
  
  func panelButtonTapped(button: PanelButtonType){
    let panelButton = coordinatorView.panelViewController.getPanelButton(button)
    
    if(button == .share) {
      showShareSheet(panelButton, layers: LayerManager.shared.layers)
    }
  }
  
  func requestLayerEdit(_ request: LayerEditRequest) {
    coordinatorView.goTo(2, data: request)
  }
  
  func requestLayerColourPicker(_ colour: UIColor, supportsAlpha: Bool = false, callback: @escaping (UIColor) -> Void) {
    let colourPicker = UIColourPickerViewController(callback: callback)
    colourPicker.supportsAlpha = supportsAlpha
    colourPicker.selectedColor = colour
    
    MapViewController.shared.lsfpc.present(colourPicker, animated: true, completion: nil)
  }
  
  func panelDidMove() {
    layerSelectView.heightDidChange()
  }
  
  func panelDidDisappear() {}
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

