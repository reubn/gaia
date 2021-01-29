import Foundation
import UIKit
import Mapbox
import FloatingPanel

class MapViewPanelViewController: UIViewController, FloatingPanelControllerDelegate {
  lazy var popoverTitle: SelectableLabel = {
    let label = SelectableLabel()
    label.text = title
    label.font = UIFont.boldSystemFont(ofSize: 25)
    label.textColor = UIColor.label
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.2
    
    view.addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true
    label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
    
    return label
  }()
  
  lazy var dismissButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.tintColor = UIColor.systemGray2

    button.addTarget(self, action: #selector(self.dismissButtonTapped), for: .touchUpInside)

    button.translatesAutoresizingMaskIntoConstraints = false
    button.widthAnchor.constraint(equalToConstant: 30).isActive = true
    button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true

    return button
  }()
  
  lazy var acceptButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .white
    button.backgroundColor = .systemGreen
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular
    
    button.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)

    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true

    return button
  }()
  
  lazy var rejectButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .white
    button.backgroundColor = .systemRed
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular

    button.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)

    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true

    return button
  }()
  
  lazy var nextButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .white
    button.backgroundColor = .systemBlue
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular

    button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true

    return button
  }()
  
  lazy var previousButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .systemBlue
    button.backgroundColor = .white
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular

    button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
    
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true
    
    return button
  }()
  
  lazy var newButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .white
    button.backgroundColor = .systemBlue
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular

    button.addTarget(self, action: #selector(newButtonTapped), for: .touchUpInside)
    
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true
    
    return button
  }()
  
  lazy var starButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "star.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit
    button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    button.tintColor = .white
    button.backgroundColor = .systemOrange
    button.layer.cornerRadius = 15
    button.layer.cornerCurve = .circular

    button.addTarget(self, action: #selector(starButtonTapped), for: .touchUpInside)
    
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2).isActive = true
    
    return button
  }()
  
  lazy var buttonsView: UIStackView = {
    let stack = UIStackView()
    
    stack.axis = .horizontal
    stack.alignment = .leading
    stack.distribution = .fillProportionally
    stack.spacing = 10
    
    view.addSubview(stack)
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    stack.centerYAnchor.constraint(equalTo: popoverTitle.centerYAnchor).isActive = true
    stack.leftAnchor.constraint(equalTo: popoverTitle.rightAnchor, constant: 10).isActive = true
    stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    
    return stack
  }()
  
  let uiImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  
  var buttons: [PanelButton] = [] {
    didSet {
      let buttonLookup: [PanelButton: UIButton] = [
        .dismiss: dismissButton,
        .accept: acceptButton,
        .reject: rejectButton,
        .next: nextButton,
        .previous: previousButton,
        .new: newButton,
        .star: starButton
      ]
      
      for subView in self.buttonsView.arrangedSubviews {
        self.buttonsView.removeArrangedSubview(subView)
        subView.removeFromSuperview()
      }
      
      for button in buttons {
        print(button, self.buttonsView.arrangedSubviews)
        self.buttonsView.addArrangedSubview(buttonLookup[button]!)
      }
      
      self.buttonsView.setNeedsLayout()
    }
  }
  
  override var title: String? {
    didSet {
      popoverTitle.text = title
    }
}
  
  init(title: String){
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
    subView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
    
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

  @objc func dismissButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }
  
  @objc func acceptButtonTapped(_ sender: UIButton) {}
  @objc func rejectButtonTapped(_ sender: UIButton) {}
  @objc func nextButtonTapped(_ sender: UIButton) {}
  @objc func previousButtonTapped(_ sender: UIButton) {}
  @objc func newButtonTapped(_ sender: UIButton) {}
  @objc func starButtonTapped(_ sender: UIButton) {}
  
  func floatingPanelWillBeginAttracting(_ fpc: FloatingPanelController, to state: FloatingPanelState) {
    uiImpactFeedbackGenerator.prepare()
  }
  
  func floatingPanelDidMove(_ vc: FloatingPanelController) {
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

enum PanelButton {
  case accept
  case dismiss
  case reject
  case next
  case previous
  case new
  case star
}
