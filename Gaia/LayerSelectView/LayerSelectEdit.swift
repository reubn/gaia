import Foundation
import UIKit
import SafariServices

import Mapbox
import KeyboardLayoutGuide

class LayerSelectEdit: UIView, CoordinatedView, UITextViewDelegate {
  unowned let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  let colourRegex = try! NSRegularExpression(pattern: "(?<=#)([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})")
  
  var _layer: Layer? = nil
  var acceptButton: PanelActionButton? = nil
  var colourEditingRange: NSRange? = nil
  
  lazy var layerManager = mapViewController.layerManager
  
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
    
    let layerDefinition = _layer != nil ? LayerDefinition(layer: _layer!) : nil
    
    if(coordinatorView.mapViewController.lsfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.lsfpc.move(to: .full, animated: true)
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
    
    mapViewController.lsfpc.track(scrollView: jsonEditor)
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
      mapViewController.lsfpc.present(vc, animated: true)
    }
  }
  
  func process(){
    let string = jsonEditor.text!
    
    do {
      var result: Bool
      let decoder = JSONDecoder()
      
      let data = string.data(using: .utf8)!

      if(_layer != nil) {
        let layerDefinition = try decoder.decode(LayerDefinition.self, from: data)
        
        _layer!.update(layerDefinition)
        layerManager.saveLayers()
        
        result = true
      } else {
        result = coordinatorView.done(data: data, url: nil)
      }
      
      if(!result) {
        throw "Could Not Save Edit"
      }
      
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      coordinatorView.goTo(0)
    } catch {
      acceptButton?.isEnabled = false
      UINotificationFeedbackGenerator().notificationOccurred(.error)
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

extension String: Error {}
extension String {
  subscript(_ range: NSRange) -> String {
    let start = self.index(self.startIndex, offsetBy: range.lowerBound)
    let end = self.index(self.startIndex, offsetBy: range.upperBound)
    let subString = self[start..<end]
    
    return String(subString)
  }
}

extension NSRegularExpression {
  func matches(_ string: String) -> [NSTextCheckingResult] {
    let range = NSRange(location: 0, length: string.utf16.count)
    
    return matches(in: string, range: range)
  }
}
