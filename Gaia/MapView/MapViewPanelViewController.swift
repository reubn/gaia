import Foundation
import UIKit
import Mapbox
import FloatingPanel

class MapViewPanelViewController: UIViewController, FloatingPanelControllerDelegate {
  let popoverTitle = UILabel()
  let dismissButton = UIButton()
  let uiImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  
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
  
  override func loadView() {
    super.loadView()
    setupTitle()
    setupDismissButton()
  }
  
  override func viewDidLoad() {
    view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
    uiImpactFeedbackGenerator.impactOccurred()
  }
  
  func setupTitle() {
    popoverTitle.text = title
    popoverTitle.font = UIFont.boldSystemFont(ofSize: 25)
    popoverTitle.textColor = UIColor.label
    
    view.addSubview(popoverTitle)
    
    popoverTitle.translatesAutoresizingMaskIntoConstraints = false
    popoverTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true
    popoverTitle.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
  }
  
  func setupDismissButton() {
    dismissButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    dismissButton.contentVerticalAlignment = .fill
    dismissButton.contentHorizontalAlignment = .fill
    dismissButton.imageView!.contentMode = .scaleAspectFit
    dismissButton.tintColor = UIColor.systemGray2
    
    dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
    dismissButton.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(dismissButton)
    
    dismissButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
    dismissButton.heightAnchor.constraint(equalTo: dismissButton.widthAnchor).isActive = true
    
    dismissButton.centerYAnchor.constraint(equalTo: popoverTitle.centerYAnchor).isActive = true
    dismissButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @IBAction func dismissButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }
  
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
}


