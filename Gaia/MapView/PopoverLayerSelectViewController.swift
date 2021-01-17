import Foundation
import UIKit
import Mapbox

class PopoverLayerSelectViewController: UIViewController {
  let layerManager: LayerManager
  let dismissButton = UIButton()
  let layerSelectView: LayerSelectView
  
  init(layerManager: LayerManager){
    self.layerManager = layerManager
    self.layerSelectView = LayerSelectView(layerManager: layerManager)
    
    super.init(nibName: nil, bundle: nil)
    
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
    setupLayerSelectView()
    setupTitle()
    setupDismissButton()
  }
  
  override func viewDidLoad() {
    view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
  }
  
  func setupTitle() {
    let label = UILabel()
    label.text = "Map Layers"
    label.font = UIFont.boldSystemFont(ofSize: 24)
    label.textColor = UIColor.label
    
    view.addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
//    label.widthAnchor.constraint(equalToConstant: 30).isActive = true
//    label.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    label.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true
    label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
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
    
    dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true
    dismissButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15).isActive = true
  }
  
  func setupLayerSelectView() {
    view.addSubview(layerSelectView)
    layerSelectView.translatesAutoresizingMaskIntoConstraints = false
    layerSelectView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    layerSelectView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    layerSelectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
    layerSelectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    layerSelectView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
    
//    layerSelectView.heightAnchor.constraint(equalToConstant: 100).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @IBAction func dismissButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

}


