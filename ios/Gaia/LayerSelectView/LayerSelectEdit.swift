import Foundation
import UIKit
import SafariServices

import Mapbox
import KeyboardLayoutGuide
import ZippyJSON

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  var request: LayerEditRequest?
  var acceptButton: PanelButton?
  var initialText: String = ""
  
  lazy var textEditor: UITextView = {
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
    
    addSubview(textView)
    
    return textView
  }()

  init(coordinatorView: LayerSelectCoordinatorView){
    self.coordinatorView = coordinatorView
    
    super.init(frame: CGRect())

    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true
  }
  
  func viewWillEnter(data: Any?){
    print("enter LSE")
    
    if(MapViewController.shared.lsfpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lsfpc.move(to: .full, animated: true)
    }
    
    coordinatorView.panelViewController.panelButtons = [.previous, .accept, .help]
    
    acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)

    textEditor.translatesAutoresizingMaskIntoConstraints = false
    textEditor.topAnchor.constraint(equalTo: topAnchor).isActive = true
    textEditor.bottomAnchor.constraint(equalTo: keyboardLayoutGuideNoSafeArea.topAnchor, constant: -10).isActive = true
    textEditor.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    textEditor.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    MapViewController.shared.lsfpc.track(scrollView: textEditor)
    
    handleRequest(request: data as? LayerEditRequest ?? .new)
  }
  
  func handleRequest(request: LayerEditRequest){
    self.request = request
    
    switch request {
      case .new:
        textEditor.text = generateNewLayerDefinitionString()
      case .edit(let layer), .duplicate(let layer):
        let layerDefinition = LayerDefinition(layer: layer)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        if let jsonData = try? encoder.encode(layerDefinition) {
          let jsonString = String(data: jsonData, encoding: .utf8)!
          
          let editorText = jsonString.replacingOccurrences(of: "\" : ", with: "\": ")
          textEditor.text = editorText
        }
    }
    
    initialText = textEditor.text
    
    textEditor.becomeFirstResponder()
    textEditor.selectedRange = NSRange(location: 0, length: 0)
    
    acceptButton?.isEnabled = true // be optimistic
    
    coordinatorView.panelViewController.title = {
      switch request {
        case .new, .duplicate:
          return "New Layer"
        case .edit:
          return "Edit Layer"
      }
    }()
  }
  
  func viewWillExit(){
    print("exit LSE")
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.goTo(0)}
    else if(button == .help) {
      let vc = SFSafariViewController(url: URL(string: "https://docs.mapbox.com/mapbox-gl-js/style-spec/root")!)
      vc.modalPresentationStyle = .popover
      MapViewController.shared.lsfpc.present(vc, animated: true)
    }
  }
  
  func process(){
  
    let regex = try? NSRegularExpression(pattern: #"^\/\/.*$"#, options: .anchorsMatchLines)
    let text = regex?.replaceMatches(textEditor.text!, with: "").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    
    if(text == initialText){
      switch request! {
        case .edit: handleError(message: .layerNotModified)
        default: ()
      }
      
      coordinatorView.goTo(0)
    
      return
    }
    
    let data = text.data(using: .utf8)!
    
    let results: LayerAcceptanceResults?
    
    switch request! {
      case .new, .duplicate:
        results = coordinatorView.acceptLayerDefinitions(from: data, methods: [.add])
      case .edit(let layer):
        results = coordinatorView.acceptLayerDefinitions(from: data, metadata: LayerDefinition.Metadata(layer: layer), methods: [.update(layer)])
    }
 
    if(results == nil){
       return self.handleError(message: .syntaxError)
     }
    
    if(results!.rejected.isEmpty) {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      HUDManager.shared.displayMessage(message: .layersAccepted(results!))

      coordinatorView.goTo(0)
    } else {
      return handleError(message: .layerRejected(results!))
    }
    
  }
  
  func handleError(message: HUDMessage){
    acceptButton?.isEnabled = false
    
    UINotificationFeedbackGenerator().notificationOccurred(.error)
    
    HUDManager.shared.displayMessage(message: message)
  }
  
  func textViewDidChange(_ textView: UITextView){
    acceptButton?.isEnabled = true
  }
  
  func generateNewLayerDefinitionString() -> String {
    let randomId = randomString(length: 6)
    let randomName = NAME_LIST.randomElement()!
    
    return """
// This file is a LayerDefinition. Style, GeoJSON, and GPX also supported

{
"metadata": {
  "id": "\(randomId)",
  "name": "\(randomName)"
  "group": "",
},
"style": {
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
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

enum LayerEditRequest {
  case new
  case edit(Layer)
  case duplicate(Layer)
}
