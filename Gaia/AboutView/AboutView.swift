import Foundation
import UIKit
import AVFoundation

import Mapbox


class AboutView: UIScrollView, UserLocationDidUpdateDelegate, ParentMapViewRegionIsChangingDelegate {
  let mapViewController: MapViewController
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
    
    view.addTarget(self, action: #selector(flip), for: .touchUpInside)
    
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
    
    mapViewController.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    mapViewController.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    
    userLocationDidUpdate()
  }
  
  func userLocationDidUpdate() {
    if(mapViewController.mapView.userLocation == nil) {return}
    let userLocation = mapViewController.mapView.userLocation!.coordinate
    
    for (index, keyLocationPair) in KEY_LOCATIONS.enumerated() {
      if(!keyLocationPair.seen && keyLocationPair.location.distance(to: userLocation) < KEY_LOCATIONS_NEEDED_LOCATION_METERS) {
        KEY_LOCATIONS[index].seen = true
        KEY_LOCATIONS[index].seenReason = .location
      }
    }
  }
  
  func parentMapViewRegionIsChanging() {
    if(mapViewController.mapView.zoomLevel < KEY_LOCATIONS_NEEDED_VIEW_ZOOM) {
      return
    }
    
    for (index, keyLocationPair) in KEY_LOCATIONS.enumerated() {
      if(!keyLocationPair.seen && MGLCoordinateInCoordinateBounds(keyLocationPair.location, mapViewController.mapView.visibleCoordinateBounds)){
        KEY_LOCATIONS[index].seen = true
        KEY_LOCATIONS[index].seenReason = .view
        
        AudioServicesPlayAlertSound(SystemSoundID(1117))
      }
    }
    
  }
  
  @objc func flip() {
    
    if(KEY_LOCATIONS.filter({$0.seenReason == .location}).count < KEY_LOCATIONS_NEEDED_LOCATION
    || KEY_LOCATIONS.filter({$0.seenReason == .view}).count < KEY_LOCATIONS_NEEDED_VIEW){
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


extension CLLocationCoordinate2D {
  func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
    let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
    let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
    
    return from.distance(from: to)
  }
}




