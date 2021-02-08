import Foundation
import UIKit
import UniformTypeIdentifiers

import Mapbox

class LayerSelectHome: UIView, CoordinatedView, UIDocumentPickerDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  lazy var layerSelectView = LayerSelectView(mutuallyExclusive: true, mapViewController: mapViewController)
  
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
  
  func showActionSheet(_ sender: UIButton) {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alertController.addAction(UIAlertAction(title: "Import from URL", style: .default, handler: {_ in
      self.coordinatorView.goTo(1)
    }))

    alertController.addAction(UIAlertAction(title: "Import from File", style: .default, handler: {_ in
      let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.xml], asCopy: true)
      documentPicker.delegate = self
      documentPicker.shouldShowFileExtensions = true
      
      self.mapViewController.lsfpc.present(documentPicker, animated: true, completion: nil)
    }))

    alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
    
    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = sender
    }

    self.mapViewController.lsfpc.present(alertController, animated: true, completion: nil)
  }
  
  func viewWillEnter(){
    print("enter LSH")
    
    if(coordinatorView.mapViewController.lsfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.lsfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Layers"
    coordinatorView.panelViewController.panelButtons = [.share, .new, .dismiss]
  }
  
  func viewWillExit(){
    print("exit LSH")
  }
  
  func panelButtonTapped(button: PanelButton){
    let panelButton = coordinatorView.panelViewController.getPanelButton(button)
    
    if(button == .new) {
      showActionSheet(panelButton)
    } else if(button == .share) {
      
      let layerDefinitions = layerManager.layers.map {LayerDefinition($0)}
      
      do {
        let encoder = JSONEncoder()
        
        let json = try encoder.encode(layerDefinitions)
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("gaiaLayerDefinitions").appendingPathExtension("json")

        try json.write(to: temporaryFileURL, options: .atomic)
        
        let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = panelButton
        self.mapViewController.lsfpc.present(activityViewController, animated: true, completion: nil)
        
      } catch {
        print(error)
      }
    }
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

