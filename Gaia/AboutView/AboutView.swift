import Foundation
import UIKit

import Mapbox


class AboutView: UIScrollView {
  let mapViewController: MapViewController
  let keyCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: LAT1, longitude: LNG1)
  var isFlipped = false
  
  lazy var appIcon: UIButton = {
    let imageView = UIButton()
    
    imageView.setImage(UIImage(named: "AppIconHighRes")!, for: .normal)
    
    let size: CGFloat = 200
    
    imageView.layer.cornerRadius = size * 0.15
    imageView.layer.cornerCurve = .continuous
    imageView.clipsToBounds = true
    
    addSubview(imageView)
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    imageView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    
    return imageView
  }()
  
  lazy var appIconBack: UIButton = {
    let view = UIButton()
    
    view.setTitle(MSG_EMOJI, for: .normal)
    view.titleLabel!.font = .systemFont(ofSize: 72)

    let size: CGFloat = 200
    
    view.backgroundColor = .tertiarySystemBackground
    view.layer.cornerRadius = size * 0.15
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
    
    view.isHidden = true
    view.isUserInteractionEnabled = true
    
    addSubview(view)
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: size).isActive = true
    view.heightAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    view.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    
    return view
  }()
  
  lazy var title: UILabel = {
    let label = UILabel()
    
    label.font = .systemFont(ofSize: 28, weight: .semibold)
    label.textColor = .label
    label.textAlignment = .center
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    label.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 30).isActive = true

    return label
  }()
  
  lazy var url: SelectableLabel = {
    let label = SelectableLabel()
    
    label.font = .systemFont(ofSize: 15)
    label.textColor = .label
    label.textAlignment = .center
    label.isSelectable = true
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    
    label.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10).isActive = true

    return label
  }()
  
  lazy var subtitle: UILabel = {
    let label = UILabel()
    
    label.font = .systemFont(ofSize: 15, weight: .medium)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    
    label.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    label.topAnchor.constraint(equalTo: url.bottomAnchor, constant: 15).isActive = true

    return label
  }()
  
  init(mapViewController: MapViewController){
    self.mapViewController = mapViewController
    
    super.init(frame: CGRect())

    setDetails()
    
    appIcon.addTarget(self, action: #selector(flip), for: .touchUpInside)
    appIconBack.addTarget(self, action: #selector(flip), for: .touchUpInside)
  }
  
  @objc func flip() {
    if(mapViewController.mapView.zoomLevel < 12 || !MGLCoordinateInCoordinateBounds(keyCoordinate, mapViewController.mapView.visibleCoordinateBounds)){
      return
    }
    
    let to = isFlipped ? appIcon : appIconBack
    let from = isFlipped ? appIconBack : appIcon
    
    let options: UIView.AnimationOptions = [
      isFlipped ? .transitionFlipFromRight : .transitionFlipFromLeft,
      .showHideTransitionViews
    ]
    
    UIView.transition(from: from, to: to, duration: 1, options: options, completion: nil)
    isFlipped = !isFlipped
    setDetails()
    
  }
  
  func setDetails(){
    title.text = !isFlipped ? "Gaia" : MSG_TITLE
    url.text = !isFlipped ? "https://reuben.science" : MSG_URL
    subtitle.text = !isFlipped ? "Phoebe x Finlay" : MSG_SUBTITLE
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}







