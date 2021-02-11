import Foundation
import UIKit

import Mapbox
import KeyboardLayoutGuide

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  var _layer: Layer? = nil
  var acceptButton: UIButton? = nil
  
  lazy var layerManager = mapViewController.layerManager
  
  lazy var jsonEditor: UITextView = {
    let textView = UITextView()
    
    textView.delegate = self

    textView.textColor = .darkGray
    textView.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
    textView.backgroundColor = .white
    textView.layer.cornerRadius = 8
    textView.layer.cornerCurve = .continuous
    textView.tintColor = .systemBlue

    textView.keyboardType = .asciiCapable
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    
    textView.text = "https://r3.cedar/config"
    
    addSubview(textView)
    
    return textView
  }()

  init(coordinatorView: LayerSelectCoordinatorView, mapViewController: MapViewController){
    self.coordinatorView = coordinatorView
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())

    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true
  }
  
  func viewWillEnter(data: Any?){
    print("enter LSE")
    
    _layer = data as? Layer
    
    let layerDefinition = _layer != nil ? LayerDefinition(_layer!) : nil
    
    if(coordinatorView.mapViewController.lsfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.lsfpc.move(to: .full, animated: true)
    }
    
    coordinatorView.panelViewController.title = _layer != nil ? "Edit Layer" : "New Layer"
    coordinatorView.panelViewController.panelButtons = [.previous, .accept]
    
    acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)

    do {
      if(layerDefinition == nil) {throw "No Layer"}
      
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

      let jsonData = try encoder.encode(layerDefinition)
      let jsonString = String(data: jsonData, encoding: .utf8)!
      
      jsonEditor.text = jsonString.replacingOccurrences(of: "\" : ", with: "\": ")
      
    } catch {
      print(error)
      
      let randomId = randomString(length: 6)
      let randomName = NAME_LIST.randomElement()!
      
      jsonEditor.text = """
{
  "metadata": {
    "id": "\(randomId)",
    "name": "\(randomName)"
    "group": "",
    "groupIndex": 0,
  },
  "styleJSON": {
    "sources": {
      "\(randomId)": {
        ...
      }
    },
    "layers": [
      {
        "id": "\(randomId)",
        "source": "\(randomId)",
        ...
      }
    ],
    "version": 8
  }
}
"""
    }
    
    jsonEditor.translatesAutoresizingMaskIntoConstraints = false
    jsonEditor.topAnchor.constraint(equalTo: topAnchor).isActive = true
    jsonEditor.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor).isActive = true
    jsonEditor.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    jsonEditor.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    jsonEditor.becomeFirstResponder()

  }
  
  func viewWillExit(){
    print("exit LSE")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.goTo(0)}
  }
  
  func process(){
    let string = jsonEditor.text!
    
    do {
      let decoder = JSONDecoder()
      
      let data = string.data(using: .utf8)!
      let layerDefinition = try decoder.decode(LayerDefinition.self, from: data)
      
      _layer?.update(layerDefinition)
      
      layerManager.saveLayers()
      
      coordinatorView.goTo(0)
    } catch {
      acceptButton?.isEnabled = false
    }
  }
  
  func textViewDidChange(_ textView: UITextView){
    acceptButton?.isEnabled = true
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension String: Error {}
