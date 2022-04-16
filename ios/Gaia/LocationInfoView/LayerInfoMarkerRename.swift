import Foundation
import UIKit

import Mapbox
import KeyboardLayoutGuide

class LocationInfoMarkerRename: UIView, CoordinatedView {
  unowned let coordinatorView: LocationInfoCoordinatorView
  
  var marker: Marker?
  
  lazy var titleInput: UITextField = {
    let textField = TextField()
    textField.placeholder = marker?.title ?? "Great Spot for a Picnic"
    textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [.foregroundColor: UIColor.gray])
    textField.textColor = .darkGray
    textField.backgroundColor = .white
    textField.layer.cornerRadius = 8
    textField.layer.cornerCurve = .continuous
    textField.tintColor = .systemBlue
    
    textField.autocorrectionType = .no

    textField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
    textField.addTarget(self, action: #selector(process), for: .editingDidEndOnExit)
    
    addSubview(textField)
    
    return textField
  }()
  
  init(coordinatorView: LocationInfoCoordinatorView){
    self.coordinatorView = coordinatorView
    super.init(frame: CGRect())
    
    layer.cornerRadius = 8
    layer.cornerCurve = .continuous
    clipsToBounds = true
  }
  
  func viewWillEnter(data: Any?){
    print("enter LIMR")
    
    guard let marker = data as? Marker else {
      return
    }
    
    self.marker = marker
    
    if(MapViewController.shared.lifpc.viewIfLoaded?.window != nil) {
      MapViewController.shared.lifpc.move(to: .half, animated: true)
    }
    
    if let title = marker.title {
      coordinatorView.panelViewController.title = "Rename Marker"
      titleInput.text = title
    } else {
      coordinatorView.panelViewController.title = "Add Title"
      titleInput.text = ""
    }
    
    coordinatorView.panelViewController.panelButtons = [.previous, .accept]
    
    titleInput.translatesAutoresizingMaskIntoConstraints = false
    titleInput.heightAnchor.constraint(equalToConstant: 60).isActive = true
    titleInput.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor).isActive = true
    titleInput.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    titleInput.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    titleInput.becomeFirstResponder()
  }
  
  func viewWillExit(){
    print("exit LIMR")
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.back()}
  }
  
  @objc func titleChanged(){
    let acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)
    
    acceptButton.isEnabled = !(titleInput.text?.isEmpty ?? true)
  }
  
  @objc func process(){
    guard
      let marker = marker,
      let newTitle = titleInput.text,
      !newTitle.isEmpty else {
      
      let acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)
      acceptButton.isEnabled = false
      return
    }
    
    coordinatorView.changeMarker(marker, title: newTitle)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
