import Foundation
import UIKit

import Mapbox
import KeyboardLayoutGuide

class LayerSelectImport: UIView, CoordinatedView {
  unowned let coordinatorView: LayerSelectCoordinatorView
  let mapViewController: MapViewController
  
  lazy var layerManager = mapViewController.layerManager
  
  lazy var urlInput: UITextField = {
    let textField = TextField()
    textField.placeholder = "/{x}/{y}/{z}, .gpx, or .json"
    textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [.foregroundColor: UIColor.gray])
    textField.textColor = .darkGray
    textField.backgroundColor = .white
    textField.layer.cornerRadius = 8
    textField.layer.cornerCurve = .continuous
    textField.tintColor = .systemBlue

    textField.keyboardType = .URL
    textField.autocapitalizationType = .none
    textField.autocorrectionType = .no
    
    textField.addTarget(self, action: #selector(urlChanged), for: .editingChanged)
    textField.addTarget(self, action: #selector(process), for: .editingDidEndOnExit)
    
    textField.text = "https://r3.cedar/config"
    
    addSubview(textField)
    
    return textField
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
    print("enter LSI")
    
    if(coordinatorView.mapViewController.lsfpc.viewIfLoaded?.window != nil) {
      coordinatorView.mapViewController.lsfpc.move(to: .half, animated: true)
    }
    
    coordinatorView.panelViewController.title = "Import Layer"
    coordinatorView.panelViewController.panelButtons = [.previous, .accept]
    
    urlInput.translatesAutoresizingMaskIntoConstraints = false
    urlInput.heightAnchor.constraint(equalToConstant: 60).isActive = true
    urlInput.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor).isActive = true
    urlInput.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    urlInput.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    urlInput.becomeFirstResponder()
    
    urlChanged()
  }
  
  func viewWillExit(){
    print("exit LSI")
  }
  
  func panelButtonTapped(button: PanelButton){
    if(button == .accept) {process()}
    else if(button == .previous) {coordinatorView.back()}
  }
  
  func validateURL(url: String) -> URLCheckingResult {
    let validAsIs = url.isValidURL()
    if(validAsIs) {
      return .validAsIs
    }
    
    let urlEncoded = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    let validIfEncoded = urlEncoded?.isValidURL() ?? false
    
    if(validIfEncoded) {
      return .validIfEncoded(urlEncoded!)
    }
    
    return .notValid
  }

  @objc func urlChanged(){
    let acceptButton = coordinatorView.panelViewController.getPanelButton(.accept)
    let urlValidation = validateURL(url: urlInput.text ?? "")
    
    switch urlValidation {
      case .validAsIs:
        acceptButton.isEnabled = true
      case .validIfEncoded:
        acceptButton.isEnabled = true
      case .notValid:
        acceptButton.isEnabled = false
    }
  }
  
  @objc func process(){
    let rawURL = (urlInput.text ?? "")
    let urlValidation = validateURL(url: rawURL)
    
    var requestURL = rawURL

    switch urlValidation {
      case .validAsIs: ()
      case .validIfEncoded(let encoded):
        requestURL = encoded
      case .notValid: return
    }
    
    URLSession.shared.dataTask(with: URL(string: requestURL)!) {data, response, error in
      let importAccepted = self.coordinatorView.done(data: data, url: rawURL)
      
      DispatchQueue.main.async {
        if(importAccepted){
          self.urlInput.resignFirstResponder()
          self.urlInput.text = ""
        } else {
          let acceptButton = self.coordinatorView.panelViewController.getPanelButton(.accept)
          acceptButton.isEnabled = false
        }
      }
    }.resume()
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class TextField: UITextField {
  let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

  override open func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }

  override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }

  override open func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
}

extension String {
  func isValidURL() -> Bool {
    // https://gist.github.com/keyvanakbary/4972366
    
    let ALPHA = "[a-zA-Z]"
    let DIGIT = "[0-9]"
    let DIGITS = "\(DIGIT)+"
    let SAFE = "[-$_.+]"
    let EXTRA = "[!*'(),]"

    let ALPHADIGIT = "[a-zA-Z0-9]"
    let TOPLABEL = "\(ALPHA)(\(ALPHADIGIT)|-)*\(ALPHADIGIT)|\(ALPHA)"
    let DOMAINLABEL = "\(ALPHADIGIT)(\(ALPHADIGIT)|-)*\(ALPHADIGIT)|\(ALPHADIGIT)"
    let HOSTNAME = "((\(DOMAINLABEL))\\.)*\(TOPLABEL)"
    let HOSTNUMBER = "\(DIGITS)\\.\(DIGITS)\\.\(DIGITS)\\.\(DIGITS)"
    let HOST = "\(HOSTNAME)|\(HOSTNUMBER)"
    let HOSTPORT = "(\(HOST))(:\(DIGITS))?"

    let HEX = "\(DIGIT)|A-F|a-f"
    let ESCAPE = "%\(HEX)\(HEX)"
    let UNRESERVED = "\(ALPHA)|\(DIGIT)|\(SAFE)|\(EXTRA)"
    let UCHAR = "\(UNRESERVED)|\(ESCAPE)"

    let HSEGMENT = "(\(UCHAR)|;|\\?|&|=)*"
    let SEARCH = "(\(UCHAR)|;|\\?|&|=)*"

    let HPATH = "\(HSEGMENT)(\\/\(HSEGMENT))*"
    let HTTPURL = "(http[s]?:\\/\\/\(HOSTPORT)(\\/\(HPATH)(\\?\(SEARCH))?)?)"

    
    guard let url = URL(string: self), UIApplication.shared.canOpenURL(url) else { return false }
    
    let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray: [HTTPURL])
    
    return predicate.evaluate(with: self)
  }
}

enum URLCheckingResult {
  case validAsIs
  case validIfEncoded(String)
  case notValid
}
