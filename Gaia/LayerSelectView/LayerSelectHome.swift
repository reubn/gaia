import Foundation
import UIKit
import UniformTypeIdentifiers

import Mapbox

class LayerSelectHome: UIView, CoordinatedView, UIDocumentPickerDelegate, LayerEditDelegate, PanelDidMoveDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  lazy var layerSelectConfig = LayerSelectConfig(
    showDisabled: [.inline, .section],
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
    
    if(results?.rejected.isEmpty ?? false) {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      HUDManager.shared.displayMessage(message: .layersAccepted(results!))
    } else {
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      HUDManager.shared.displayMessage(
        message: results != nil
          ? .layerRejected(results!, importing: true)
          : .syntaxError
      )
    }
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
  
  func showShareSheet(_ sender: PanelActionButton, layers: [Layer]) {
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
    
    coordinatorView.panelViewController.panelDidMoveDelegate = self
    
    if(MapViewController.shared.lsfpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lsfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Layers"
    coordinatorView.panelViewController.panelButtons = [.share, .new, .dismiss]

    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
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
      UIAction(title: "New from Map", image: UIImage(systemName: "map"), attributes: LayerManager.shared.compositeStyle.sortedLayers.isEmpty ? [.hidden] : [], handler: {_ in
        let randomId = randomString(length: 6)
        
        let layerDefinition = LayerDefinition(
          metadata: LayerDefinition.Metadata(
            id: "composite_\(randomId)",
            name: "Composite Layer",
            group: ""
          ),
          style: LayerManager.shared.compositeStyle.style
        )
        
        _ = self.coordinatorView.acceptLayerDefinitions(from: [layerDefinition])
      }),
      UIAction(title: "New", image: UIImage(systemName: "plus"), handler: {_ in
        self.requestLayerEdit(.new)
      })
    ])
    newButton.adjustsImageWhenHighlighted = false
    newButton.showsMenuAsPrimaryAction = true
  }
  
  func viewWillExit(){
    print("exit LSH")
    
    coordinatorView.panelViewController.panelDidMoveDelegate = nil
    
    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
    
    newButton.menu = nil
    newButton.adjustsImageWhenHighlighted = true
    newButton.showsMenuAsPrimaryAction = false
  }
  
  func panelButtonTapped(button: PanelButton){
    let panelButton = coordinatorView.panelViewController.getPanelButton(button)
    
    if(button == .share) {
      showShareSheet(panelButton, layers: LayerManager.shared.layers)
    }
  }
  
  func requestLayerEdit(_ request: LayerEditRequest) {
    coordinatorView.goTo(2, data: request)
  }
  
  func panelDidMove() {
    layerSelectView.heightDidChange()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

