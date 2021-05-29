import Foundation
import UIKit
import AVFoundation

import Mapbox

class AboutView: UIScrollView, UserLocationDidUpdateDelegate, ParentMapViewRegionIsChangingDelegate {
  var emojiTimer: Timer? = nil
  var isFlipped = false
  
  lazy var appIcon: AppIcon = {
    let imageView = AppIcon()

    imageView.setImage(UIImage(named: BUNDLE_ID_SUFFIX == ".dev" ? "AppIconHighRes.dev" : "AppIconHighRes")!, for: .normal)
    
    imageView.layer.cornerCurve = .continuous
    imageView.clipsToBounds = true
    
    addSubview(imageView)
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    imageView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
    
    return imageView
  }()
  
  lazy var appIconBack: AppIcon = {
    let view = AppIcon()
    
    view.setTitle(MSG_EMOJI[MSG_EMOJI_INDEX], for: .normal)
    view.titleLabel!.font = .systemFont(ofSize: 72)
    
    view.backgroundColor = .tertiarySystemBackground
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
    
    view.isHidden = true
    
    view.addTarget(self, action: #selector(flip), for: .touchUpInside)

    addSubview(view)
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
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
    label.topAnchor.constraint(greaterThanOrEqualTo: appIcon.bottomAnchor, constant: 10).isActive = true

    return label
  }()
  
  lazy var url: SelectableLabel = {
    let label = SelectableLabel()
    
    label.font = .systemFont(ofSize: 15)
    label.textColor = .label
    label.textAlignment = .center
    label.isSelectable = true
    
    addSubview(label)
    
    let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.didTapURL(_:   )))
    label.addGestureRecognizer(labelTap)
    
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
    label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -15).isActive = true

    return label
  }()
  
  init(){
    super.init(frame: CGRect())

    setDetails()
    
    appIcon.addTarget(self, action: #selector(flip), for: .touchUpInside)
    
    MapViewController.shared.multicastUserLocationDidUpdateDelegate.add(delegate: self)
    MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
    
    userLocationDidUpdate()
  }
  
  func userLocationDidUpdate() {
    if(MapViewController.shared.mapView.userLocation == nil) {return}
    let userLocation = MapViewController.shared.mapView.userLocation!.coordinate
    
    for (index, keyLocationPair) in KEY_LOCATIONS.enumerated() {
      if(!keyLocationPair.seen && keyLocationPair.location.distance(to: userLocation) < KEY_LOCATIONS_NEEDED_LOCATION_METERS) {
        KEY_LOCATIONS[index].seen = true
        KEY_LOCATIONS[index].seenReason = .location
      }
    }
  }
  
  func parentMapViewRegionIsChanging() {
    if(MapViewController.shared.mapView.zoomLevel < KEY_LOCATIONS_NEEDED_VIEW_ZOOM) {
      return
    }
    
    for (index, keyLocationPair) in KEY_LOCATIONS.enumerated() {
      if(!keyLocationPair.seen && MapViewController.shared.mapView.visibleCoordinateBounds.contains(coordinate: keyLocationPair.location)){
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
    
    if(!isFlipped) {emojiTimer?.invalidate()}
    else {
      emojiTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
        if(MapViewController.shared.presentedViewController != MapViewController.shared.abfpc) {
          timer.invalidate() // Release
        }

        MSG_EMOJI_INDEX = (MSG_EMOJI_INDEX + 1) % MSG_EMOJI.count
        
        self.appIconBack.setTitle(MSG_EMOJI[MSG_EMOJI_INDEX], for: .normal)
      }
    }
  }
  
  @objc func didTapURL(_ sender: UIGestureRecognizer) {
    let url = URL(string: (sender.view as? UILabel)?.text ?? "")
    
    if(url != nil && UIApplication.shared.canOpenURL(url!)){
      UIApplication.shared.open(url!)
    }
  }
  
  func setDetails(){
    title.text = !isFlipped ? Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String : MSG_TITLE
    url.text = !isFlipped ? "https://reuben.science" : MSG_URL
    subtitle.text = !isFlipped ? "Phoebe x Finlay" : MSG_SUBTITLE
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class AppIcon: UIButton {
  override func layoutSubviews() {
    super.layoutSubviews()
    self.layer.cornerRadius = frame.height * 0.15
  }
}

struct KeyLocationPair {
  var location: CLLocationCoordinate2D
  var seen: Bool = false
  var seenReason: SeenReason? = nil
  
  enum SeenReason {
    case location
    case view
  }
}