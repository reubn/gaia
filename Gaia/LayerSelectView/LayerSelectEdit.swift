import Foundation
import UIKit
import SafariServices

import Mapbox
import KeyboardLayoutGuide

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  let colourRegex = try! NSRegularExpression(pattern: "(?<=#)([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})")
  
  var request: LayerEditRequest?
  var acceptButton: PanelActionButton?
  var colourEditingRange: NSRange?
  
  var initialText: String = ""
  
  lazy var colorWell: UIColorWell = {
    let colorWell = UIColorWell()
    
    colorWell.isHidden = true

    addSubview(colorWell)
    
    colorWell.translatesAutoresizingMaskIntoConstraints = false
    colorWell.rightAnchor.constraint(equalTo: jsonEditor.rightAnchor, constant: -10).isActive = true
    colorWell.bottomAnchor.constraint(equalTo: jsonEditor.bottomAnchor, constant: -10).isActive = true
    
    return colorWell
  }()
  
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

    jsonEditor.translatesAutoresizingMaskIntoConstraints = false
    jsonEditor.topAnchor.constraint(equalTo: topAnchor).isActive = true
    jsonEditor.bottomAnchor.constraint(equalTo: keyboardLayoutGuideNoSafeArea.topAnchor, constant: -10).isActive = true
    jsonEditor.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    jsonEditor.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    jsonEditor.becomeFirstResponder()
    jsonEditor.selectedRange = NSRange(location: 0, length: 0)
    
    colorWell.addTarget(self, action: #selector(colourChanged), for: .valueChanged)
    
    MapViewController.shared.lsfpc.track(scrollView: jsonEditor)
    
    handleRequest(request: data as? LayerEditRequest ?? .new)
  }
  
  func handleRequest(request: LayerEditRequest){
    self.request = request
    
    let layerDefinition: LayerDefinition? = {
      switch request {
        case .new:
          return nil
        case .edit(let layer), .duplicate(let layer):
          return LayerDefinition(layer: layer)
      }
    }()
    
    do {
      if(layerDefinition == nil) {throw "No Layer"}

      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]

      let jsonData = try encoder.encode(layerDefinition)
      let jsonString = String(data: jsonData, encoding: .utf8)!

      let editorText = jsonString.replacingOccurrences(of: "\" : ", with: "\": ")
      jsonEditor.text = editorText
    } catch {
      print(error)

      jsonEditor.text = generateNewLayerDefinitionString()
    }
    
    initialText = jsonEditor.text
    acceptButton?.isEnabled = true // be optimistic
    
    coordinatorView.panelViewController.title = {
      switch request {
        case .new, .duplicate:
          return "New Layer"
        case .edit:
          return "Edit Layer"
      }
    }()
    
    parseTextForColours()
  }
  
  func viewWillExit(){
    print("exit LSE")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.goTo(0)}
    else if(button == .help) {
      let vc = SFSafariViewController(url: URL(string: "https://docs.mapbox.com/mapbox-gl-js/style-spec/root")!)
      vc.modalPresentationStyle = .popover
      MapViewController.shared.lsfpc.present(vc, animated: true)
    }
  }
  
  func process(){
    let jsonText = jsonEditor.text!
    
    do {
      if(jsonText == initialText){
        handleError(message: .layerNotModified)
        coordinatorView.goTo(0)
        
        return
      }
      
      let decoder = JSONDecoder()
      
      let data = jsonText.data(using: .utf8)!
      let layerDefinition = try decoder.decode(LayerDefinition.self, from: data)
      
      let method: LayerAcceptanceMethod = {
        switch request! {
          case .new, .duplicate:
            return .add
        case .edit(let layer):
            return .update(layer)
        }
      }()
      
      let results = coordinatorView.acceptLayerDefinitions(from: [layerDefinition], methods: [method])
      
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
    } catch {
      print(error)
      handleError(message: .syntaxError)
    }
  }
  
  func handleError(message: HUDMessage){
    acceptButton?.isEnabled = false
    
    UINotificationFeedbackGenerator().notificationOccurred(.error)
    
    HUDManager.shared.displayMessage(message: message)
  }
  
  func textViewDidChange(_ textView: UITextView){
    acceptButton?.isEnabled = true
    parseTextForColours()
  }
  
  func parseTextForColours(){
    let colourMatches = colourRegex.matches(jsonEditor.text)

    if(colourMatches.count == 1) {
      let match = colourMatches[0]
      let range = match.range
      
      let hex = String(jsonEditor.text[range])
      let uiColor = UIColor(hex: hex)

      if(uiColor != nil) {
        self.colorWell.selectedColor = uiColor!
        self.colorWell.isHidden = false
        self.colourEditingRange = range
      }
    } else {
      self.colorWell.selectedColor = nil
      self.colorWell.isHidden = true
    }
  }
  
  func generateNewLayerDefinitionString() -> String {
    let randomId = randomString(length: 6)
    let randomName = NAME_LIST.randomElement()!
    
    return """
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
  
  @objc func colourChanged(){
    let selectedColour = colorWell.selectedColor!
    
    let hexString = selectedColour.toHex()!

    let replaced = (jsonEditor.text as NSString).replacingCharacters(in: colourEditingRange!, with: hexString)
    
    colourEditingRange = NSRange(location: colourEditingRange!.location, length: hexString.count)

    jsonEditor.text = String(replaced)
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
