import Foundation
import UIKit
import Mapbox
import FloatingPanel

class PanelViewController: UIViewController, FloatingPanelControllerDelegate {
  var panelDelegate: PanelDelegate?
  
  lazy var popoverTitle: SelectableLabel = {
    let label = SelectableLabel()
    label.text = title
    label.font = UIFont.boldSystemFont(ofSize: 25)
    label.textColor = UIColor.label
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.2
    
    label.accessibilityTraits = .header
    
    view.addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
    
    return label
  }()
  
  lazy var buttonsView: UIStackView = {
    let stack = UIStackView()
    
    stack.axis = .horizontal
    stack.alignment = .center
    stack.distribution = .fillProportionally
    stack.spacing = 10
    
    view.addSubview(stack)
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    stack.leftAnchor.constraint(equalTo: popoverTitle.rightAnchor, constant: 10).isActive = true
    stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    
    return stack
  }()
  
  let uiImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  
  private lazy var buttonsMap: [PanelButtonType: PanelButton] = [
    .dismiss: PanelSmallButton("xmark", weight: .bold, colour: .systemGray, backgroundColour: .tertiarySystemBackground),
    .help: PanelSmallButton("questionmark", colour: .white, backgroundColour: .systemIndigo),
    .settings: PanelButton("gear", inset: 6, colour: .white, backgroundColour: .systemGray),
    .accept: PanelButton("checkmark", colour: .systemGreen),
    .reject: PanelButton("xmark", colour: .systemRed),
    .next: PanelButton("arrow.right"),
    .previous: PanelButton("arrow.left", deemphasise: true),
    .new: PanelButton("plus"),
    .star: PanelButton("star.fill", colour: .systemOrange),
    .share: PanelButton("square.and.arrow.up", deemphasise: true)
  ]
  
  var panelButtons: [PanelButtonType] = [] {
    didSet {
      for subView in self.buttonsView.arrangedSubviews {
        self.buttonsView.removeArrangedSubview(subView)
        subView.removeFromSuperview()
      }
      
      for panelButton in panelButtons {
        let button = buttonsMap[panelButton]!
        
        button.isEnabled = true
        button.addTarget(self, action: #selector(_panelButtonTapped(_:)), for: .touchUpInside)
        self.buttonsView.addArrangedSubview(button)
      }
      
      self.buttonsView.setNeedsLayout()
    }
  }
  
  @objc private func _panelButtonTapped(_ sender: PanelButton){
    panelButtonTapped(button: buttonsMap.key(forValue: sender)!)
  }
  
  func getPanelButton(_ button: PanelButtonType) -> PanelButton {
    return buttonsMap[button]!
  }
  
  func panelButtonTapped(button: PanelButtonType){
    if(button == .dismiss) {
      dismiss(animated: true, completion: nil)
      
      return
    }
  }
  
  override var title: String? {
    didSet {
      popoverTitle.text = title
    }
}
  
  init(title: String?){
    super.init(nibName: nil, bundle: nil)
    self.title = title
    
    view.backgroundColor = UIColor.clear
    view.clipsToBounds = false;
    view.layer.shadowColor = UIColor.black.cgColor;
    view.layer.shadowOffset = CGSize(width: 0, height: 0);
    view.layer.shadowOpacity = 0.25;
    view.layer.shadowRadius = 10;
    
    let subView = UIView(frame: view.bounds)
    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)
    
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
    blur.frame = subView.bounds
    blur.autoresizingMask = subView.autoresizingMask
    blur.isUserInteractionEnabled = false

    subView.insertSubview(blur, at: 0)
    view.insertSubview(subView, at: 0)
    
    subView.layer.masksToBounds = true
    subView.clipsToBounds = true
  }
  
  
  override func viewDidLoad() {
    uiImpactFeedbackGenerator.impactOccurred()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    self.panelDelegate?.panelDidDisappear()
  }

  func floatingPanelWillBeginAttracting(_ fpc: FloatingPanelController, to state: FloatingPanelState) {
    uiImpactFeedbackGenerator.prepare()
  }
  
  func floatingPanelDidMove(_ vc: FloatingPanelController) {
    self.panelDelegate?.panelDidMove()
    
    if vc.isAttracting == false {
      let loc = vc.surfaceLocation
      let minY = vc.surfaceLocation(for: .full).y - 6.0
      vc.surfaceLocation = CGPoint(x: loc.x, y: max(loc.y, minY))
    }
  }
  
  func floatingPanelDidEndAttracting(_ fpc: FloatingPanelController) {
    uiImpactFeedbackGenerator.impactOccurred()
  }
  
  func floatingPanelDidEndDragging(_ fpc: FloatingPanelController, willAttract attract: Bool){
    if(!attract) {
      uiImpactFeedbackGenerator.impactOccurred()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

enum PanelButtonType {
  case accept
  case dismiss
  case reject
  case next
  case previous
  case new
  case star
  case share
  case help
  case settings
}

protocol PanelDelegate {
  func panelDidDisappear()
  func panelDidMove()
}

extension Dictionary where Value: Equatable {
  func key(forValue value: Value) -> Key? {
    first {$0.1 == value}?.0
  }
}
