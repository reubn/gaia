import Foundation
import UIKit
import SafariServices

import Mapbox
import KeyboardLayoutGuide

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
    
  let colourRegex = try! NSRegularExpression(pattern: "(?<=#)([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})")
  
  var _layer: Layer? = nil
  var acceptButton: PanelActionButton? = nil
  var colourEditingRange: NSRange? = nil
  
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
    
    var duplicateFromLayer: Layer?
    (_layer, duplicateFromLayer) = data as! (Layer?, Layer?)
    
    let layerDefinition = (_layer ?? duplicateFromLayer) != nil
      ? LayerDefinition(layer: (_layer ?? duplicateFromLayer)!)
      : nil
    
    if(MapViewController.shared.lsfpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lsfpc.move(to: .full, animated: true)
    }
    
    coordinatorView.panelViewController.title = _layer != nil ? "Edit Layer" : "New Layer"
    coordinatorView.panelViewController.panelButtons = [.previous, .accept, .help]
    
    acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)

    do {
      if(layerDefinition == nil) {throw "No Layer"}
      
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]

      let jsonData = try encoder.encode(layerDefinition)
      let jsonString = String(data: jsonData, encoding: .utf8)!
      
      let editorText = jsonString.replacingOccurrences(of: "\" : ", with: "\": ")
      jsonEditor.text = editorText
      
      initialText = editorText
      
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
    

    jsonEditor.translatesAutoresizingMaskIntoConstraints = false
    jsonEditor.topAnchor.constraint(equalTo: topAnchor).isActive = true
    jsonEditor.bottomAnchor.constraint(equalTo: keyboardLayoutGuideNoSafeArea.topAnchor, constant: -10).isActive = true
    jsonEditor.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    jsonEditor.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    jsonEditor.becomeFirstResponder()
    jsonEditor.selectedRange = NSRange(location: 0, length: 0)
    
    parseTextForColours()
    
    colorWell.addTarget(self, action: #selector(colourChanged), for: .valueChanged)
    
    MapViewController.shared.lsfpc.track(scrollView: jsonEditor)
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
    let string = jsonEditor.text!
    
    if(string == initialText){
      coordinatorView.goTo(0)
      
      return
    }
    
    do {
      var result: Bool
      var newLayer = false
      let decoder = JSONDecoder()
      
      let data = string.data(using: .utf8)!

      if(_layer != nil) {
        let layerDefinition = try decoder.decode(LayerDefinition.self, from: data)
        
        // this could be consolidated to use coordinatorView.done
        _layer!.update(layerDefinition)
        LayerManager.shared.saveLayers()
        
        result = true
      } else {
        result = coordinatorView.done(data: data, url: nil).accepted != 0
        newLayer = true
      }
      
      if(!result) {
        throw "Could Not Save Edit"
      }
      
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      HUDManager.shared.displayMessage(message: newLayer ? .layerCreated : .layerSaved)
      
      coordinatorView.goTo(0)
    } catch {
      acceptButton?.isEnabled = false
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      HUDManager.shared.displayMessage(message: .syntaxError)
    }
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
