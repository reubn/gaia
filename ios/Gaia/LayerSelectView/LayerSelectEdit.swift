import Foundation
import UIKit
import SafariServices

import Mapbox
import KeyboardLayoutGuide
import ZippyJSON

import Runestone
import TreeSitterJSONRunestone

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  var request: LayerEditRequest?
  var acceptButton: PanelButton?
  var helpButton: PanelButton?
  var initialText: String = ""
  var text: String {
    set {
      let state = TextViewState(text: newValue, theme: PlainTextTheme.shared, language: .json)
      textEditor.setState(state)
    }
    
    get {
      textEditor.text
    }
  }
  
  lazy var textEditor: TextView = {
    let textView = TextView()
    
    textView.delegate = self
    textView.layer.cornerRadius = 8
    textView.layer.cornerCurve = .continuous
    textView.tintColor = .systemBlue

    textView.keyboardType = .asciiCapable
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    
    textView.showLineNumbers = false
    textView.showPageGuide = false
    
    textView.lineSelectionDisplayType = .disabled
    
    textView.showTabs = false
    textView.showSpaces = false
    textView.showLineBreaks = false
    textView.showSoftLineBreaks = false

    textView.lineHeightMultiplier = 1.3
    
    textView.isLineWrappingEnabled = false
    
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
    helpButton = coordinatorView.panelViewController.getPanelButton(.help)
    
    helpButton?.menu = UIMenu(title: "Supported Formats", children: [
      UIAction(title: "Layer Definition", handler: {_ in}),
      UIAction(title: "Style (JSON)", image: UIImage(systemName: "arrow.up.forward.square"), handler: {_ in
        let vc = SFSafariViewController(url: URL(string: "https://docs.mapbox.com/mapbox-gl-js/style-spec/root")!)
        vc.modalPresentationStyle = .popover
        MapViewController.shared.lsfpc.present(vc, animated: true)
      }),
      UIAction(title: "GeoJSON", image: UIImage(systemName: "arrow.up.forward.square"), handler: {_ in
        let vc = SFSafariViewController(url: URL(string: "https://geojson.org/")!)
        vc.modalPresentationStyle = .popover
        MapViewController.shared.lsfpc.present(vc, animated: true)
      }),
      UIAction(title: "GPX", image: UIImage(systemName: "arrow.up.forward.square"), handler: {_ in
        let vc = SFSafariViewController(url: URL(string: "https://www.topografix.com/gpx.asp")!)
        vc.modalPresentationStyle = .popover
        MapViewController.shared.lsfpc.present(vc, animated: true)
      })
    ])
    
    helpButton?.showsMenuAsPrimaryAction = true

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
        text = generateNewLayerDefinitionString()
      case .edit(let layer), .duplicate(let layer):
        let layerDefinition = LayerDefinition(layer: layer)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        if let jsonData = try? encoder.encode(layerDefinition) {
          let jsonString = String(data: jsonData, encoding: .utf8)!
          
          let spacedColonRegex = try! NSRegularExpression(pattern: #"\s:"#)
          let emptySquareBracketsRegex = try! NSRegularExpression(pattern: #"(\[\s+\])"#)
          let emptyCurlyBracketsRegex = try! NSRegularExpression(pattern: #"(\{\s+\})"#)

          text = [
            (spacedColonRegex, ":"),
            (emptyCurlyBracketsRegex, "{}"),
            (emptySquareBracketsRegex, "[]")
          ].reduce(jsonString, {(result, regexPair) in regexPair.0.replaceMatches(result, with: regexPair.1)})
        }
    }
    
    initialText = text
    
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
  
  func update(data: Any?) {}
  
  func viewWillExit(){
    print("exit LSE")
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.goTo(0)}
    else if(button == .help) {
      helpButton?.isPulsing = false
    }
  }
  
  func process(){
  
    let regex = try? NSRegularExpression(pattern: #"^\/\/.*$"#, options: .anchorsMatchLines)
    let text = regex?.replaceMatches(text, with: "").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    
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
    helpButton?.isPulsing = true
    
    UINotificationFeedbackGenerator().notificationOccurred(.error)
    
    HUDManager.shared.displayMessage(message: message)
  }
  
  func textViewDidChange(_ textView: UITextView){
    acceptButton?.isEnabled = true
    helpButton?.isPulsing = false
  }
  
  func generateNewLayerDefinitionString() -> String {
    let randomId = randomString(length: 6)
    let randomName = NAME_LIST.randomElement()!
    
    return """
// LayerDefinition

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
