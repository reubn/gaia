import Foundation
import UIKit
import UniformTypeIdentifiers

import Mapbox

class LayerSelectHome: UIView, CoordinatedView, UIDocumentPickerDelegate {
  let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  lazy var layerSelectView = LayerSelectView(mapViewController: mapViewController)
  
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
      let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
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
    coordinatorView.panelViewController.buttons = [.new, .dismiss]
  }
  
  func viewWillExit(){
    print("exit LSH")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .dismiss) {coordinatorView.panelViewController.dismiss(animated: true, completion: nil)}
    else if(button == .new) {showActionSheet(coordinatorView.panelViewController.newButton)}
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

