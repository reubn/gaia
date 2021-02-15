import Foundation
import UIKit
import UniformTypeIdentifiers

import Mapbox

class LayerSelectHome: UIView, CoordinatedView, UIDocumentPickerDelegate, LayerEditDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerSelectConfig = LayerSelectConfig(mutuallyExclusive: true, layerContextActions: true, reorderLayers: true, layerEditDelegate: self)
  
  lazy var layerManager = mapViewController.layerManager
  lazy var layerSelectView = LayerSelectView(layerSelectConfig: layerSelectConfig, mapViewController: mapViewController)
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    if let url = urls.first {
      print(url)
      
      let data = try? Data(contentsOf: url)
      if(data != nil) {
        self.coordinatorView.done(data: data!)
      }
      
    }
  }

  init(coordinatorView: LayerSelectCoordinatorView, mapViewController: MapViewController){
    self.coordinatorView = coordinatorView
    self.mapViewController = mapViewController
    
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
      self.mapViewController.lsfpc.present(activityViewController, animated: true, completion: nil)
      
    } catch {
      print(error)
    }
  }

  func viewWillEnter(data: Any?){
    print("enter LSH")
    
    if(coordinatorView.mapViewController.lsfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.lsfpc.move(to: .half, animated: true)
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

        self.mapViewController.lsfpc.present(documentPicker, animated: true, completion: nil)
      }),
      UIAction(title: "New", image: UIImage(systemName: "plus"), handler: {_ in
        self.coordinatorView.goTo(2)
      })
    ])
    newButton.adjustsImageWhenHighlighted = false
    newButton.showsMenuAsPrimaryAction = true
  }
  
  func viewWillExit(){
    print("exit LSH")
    
    let newButton = coordinatorView.panelViewController.getPanelButton(.new)
    
    newButton.menu = nil
    newButton.adjustsImageWhenHighlighted = true
    newButton.showsMenuAsPrimaryAction = false
  }
  
  func panelButtonTapped(button: PanelButton){
    let panelButton = coordinatorView.panelViewController.getPanelButton(button)
    
    if(button == .share) {
      showShareSheet(panelButton, layers: layerManager.layers)
    }
  }
  
  func layerEditWasRequested(layer: Layer) {
    coordinatorView.goTo(2, data: layer)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

