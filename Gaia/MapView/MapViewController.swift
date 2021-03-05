import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate, LayerManagerDelegate, OfflineModeDelegate {
  let lsfpc = MemoryConsciousFloatingPanelController()
  let osfpc = MemoryConsciousFloatingPanelController()
  let lifpc = MemoryConsciousFloatingPanelController()
  let abfpc = MemoryConsciousFloatingPanelController()
  
  let layersButton = MapButton()
  let infoButton = MapButton()
  let offlineButton = MapButton()
  
  let uiColourTint: UIColor = .systemBlue
  
  let multicastParentMapViewRegionIsChangingDelegate = MulticastDelegate<(ParentMapViewRegionIsChangingDelegate)>()
  let multicastUserLocationDidUpdateDelegate = MulticastDelegate<(UserLocationDidUpdateDelegate)>()
  let multicastMapViewTappedDelegate = MulticastDelegate<(MapViewTappedDelegate)>()

  var mapView: MGLMapView!
  var rasterLayer: MGLRasterStyleLayer?
  var userLocationButton: UserLocationButton?
  var firstTimeLocating = true
  
  override func viewDidLoad() {
    super.viewDidLoad()

    mapView = MGLMapView(frame: view.bounds)
    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    let initialCompositeStyle = LayerManager.shared.compositeStyle
    mapView.styleURL = initialCompositeStyle.url
    updateUIColourScheme(compositeStyle: initialCompositeStyle)

    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mapView.logoView.isHidden = true
    mapView.attributionButton.isHidden = true
    
    mapView.userTrackingMode = .followWithHeading
    mapView.compassView.compassVisibility = .visible
    mapView.zoomLevel = 11
    
    setUpCompass()

    mapView.tintColor = .systemBlue // user location should always be blue

    mapView.delegate = self
    
    let singleTapGR = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
    
    for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
      singleTapGR.require(toFail: recognizer)
    }
    
    mapView.addGestureRecognizer(singleTapGR)

    view.addSubview(mapView)

    let mapLongPressGR = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPress))
    mapLongPressGR.numberOfTouchesRequired = 1
    mapView.addGestureRecognizer(mapLongPressGR)
    
    let mapDoubleTapGR = UITapGestureRecognizer(target: self, action: #selector(twoFingerTapped))
    mapDoubleTapGR.numberOfTapsRequired = 1
    mapDoubleTapGR.numberOfTouchesRequired = 2
    mapView.addGestureRecognizer(mapDoubleTapGR)

    let mapTripleTapGR = UITapGestureRecognizer(target: self, action: #selector(threeFingerTapped))
    mapTripleTapGR.numberOfTapsRequired = 1
    mapTripleTapGR.numberOfTouchesRequired = 3
    mapView.addGestureRecognizer(mapTripleTapGR)

    let userLocationButton = UserLocationButton(initialMode: mapView.userTrackingMode)
    userLocationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    userLocationButton.translatesAutoresizingMaskIntoConstraints = false
    userLocationButton.accessibilityLabel = "Change Tracking Mode"
    
    self.userLocationButton = userLocationButton
    
    let userLocationButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(locationButtonLongPressed))
    userLocationButtonLongGR.minimumPressDuration = 0.4
    userLocationButton.addGestureRecognizer(userLocationButtonLongGR)

    layersButton.setImage(UIImage(systemName: "map"), for: .normal)
    layersButton.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
    layersButton.accessibilityLabel = "Layers"
    
    let layersButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(layersButtonLongPressed))
    layersButtonLongGR.minimumPressDuration = 0.4
    layersButton.addGestureRecognizer(layersButtonLongGR)
    
    offlineButton.setImage(OfflineManager.shared.offlineMode ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
    offlineButton.addTarget(self, action: #selector(offlineButtonTapped), for: .touchUpInside)
    offlineButton.accessibilityLabel = "Downloads"
    
    let offlineButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(offlineButtonLongPressed))
    offlineButtonLongGR.minimumPressDuration = 0.4
    offlineButton.addGestureRecognizer(offlineButtonLongGR)
    
    let mapButtonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, offlineButton])

    view.addSubview(mapButtonGroup)
    
    mapButtonGroup.translatesAutoresizingMaskIntoConstraints = false
    mapButtonGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36 + 20).isActive = true
    mapButtonGroup.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -6).isActive = true
    
    let appIconButton = AppIconButton()
    
    view.addSubview(appIconButton)
    
    appIconButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10).isActive = true
    appIconButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
    
    appIconButton.addTarget(self, action: #selector(appIconButtonTapped), for: .touchUpInside)
    appIconButton.accessibilityLabel = "About"
    
  }
  
  @objc func mapViewTapped(){
    multicastMapViewTappedDelegate.invoke(invocation: {$0.mapViewTapped()})
  }
  
  func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?){
    multicastUserLocationDidUpdateDelegate.invoke(invocation: {$0.userLocationDidUpdate()})
    
    if(firstTimeLocating && userLocation?.location != nil) {
      mapView.centerCoordinate = userLocation!.location!.coordinate
      mapView.userTrackingMode = .follow
      firstTimeLocating = false
    }
  }
  
  func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
    openLocationInfoPanel(location: .user)
    
    mapView.deselectAnnotation(annotation, animated: false)
  }

  func mapViewRegionIsChanging(_ mapView: MGLMapView) {
    multicastParentMapViewRegionIsChangingDelegate.invoke(invocation: {$0.parentMapViewRegionIsChanging()})
  }

  func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
    guard let userLocationButton = userLocationButton else { return }

    if(mode != .followWithHeading) {
      mapView.resetNorth()

      if(mode != .follow) {
        mapView.showsUserLocation = false
      }
    }

    userLocationButton.updateArrowForTrackingMode(mode: mode)
  }
  
  func compositeStyleDidChange(compositeStyle: CompositeStyle) {
    mapView.styleURL = compositeStyle.url
    updateUIColourScheme(compositeStyle: compositeStyle)
  }
  
  func updateUIColourScheme(compositeStyle: CompositeStyle){
    DispatchQueue.main.async { [self] in
      let dark = compositeStyle.needsDarkUI
      mapView.window?.overrideUserInterfaceStyle = dark ? .dark : .light
      mapView.window?.tintColor = dark ? .white : uiColourTint
      mapView.compassView.image = compassImage(dark: dark)
    }
  }
  
  func offlineModeDidChange(offline: Bool){
    offlineButton.setImage(offline ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
  }
  
  @objc func mapLongPress(gestureReconizer: UILongPressGestureRecognizer){
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      let point = gestureReconizer.location(in: mapView)
      let coordinate = mapView.convert(point, toCoordinateFrom: nil)
      
      openLocationInfoPanel(location: .map(coordinate))
    }
  }

  @objc func locationButtonTapped(sender: UserLocationButton) {
    var mode: MGLUserTrackingMode

    switch (mapView.userTrackingMode) {
      case .none:
        mode = .follow
      case .follow:
        mode = .followWithHeading
      case .followWithHeading:
        mode = .follow
      case .followWithCourse:
        mode = .none
      @unknown default:
        fatalError("Unknown user tracking mode")
    }

    mapView.userTrackingMode = mode
  }
  
  @objc func locationButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      openLocationInfoPanel(location: .user)
    }
  }
  
  func openLocationInfoPanel(location: LocationInfoType) {
    if presentedViewController != nil {
      let isMe = presentedViewController == lifpc

      if(isMe) {
        ((presentedViewController as! MemoryConsciousFloatingPanelController).contentViewController! as! LocationInfoPanelViewController).update(location: location)
        
        return
      } else {
        presentedViewController!.dismiss(animated: false, completion: nil)
      }
    }

    let locationInfoPanelViewController = LocationInfoPanelViewController(location: location)
    
    lifpc.layout = locationInfoPanelLayout
    lifpc.delegate = locationInfoPanelViewController
    lifpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
    lifpc.isRemovalInteractionEnabled = true
    lifpc.contentMode = .fitToBounds
    
    let appearance = SurfaceAppearance()
//    appearance.cornerCurve = CALayerCornerCurve.continuous
    appearance.cornerRadius = 16
    appearance.backgroundColor = .clear
    lifpc.surfaceView.appearance = appearance
    
    lifpc.set(contentViewController: locationInfoPanelViewController)

    self.present(lifpc, animated: true, completion: nil)
  }

  @objc func layersButtonTapped(sender: MapButton) {
    if presentedViewController != nil {
      let isMe = presentedViewController == lsfpc
      presentedViewController!.dismiss(animated: isMe, completion: nil)
      
      if(isMe) {return}
    }

    let layerSelectPanelViewController = LayerSelectPanelViewController()
    
    lsfpc.layout = layerSelectPanelLayout
    lsfpc.delegate = layerSelectPanelViewController
    lsfpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
    lsfpc.isRemovalInteractionEnabled = true
    lsfpc.contentMode = .fitToBounds
    
    let appearance = SurfaceAppearance()
//    appearance.cornerCurve = CALayerCornerCurve.continuous
    appearance.cornerRadius = 16
    appearance.backgroundColor = .clear
    lsfpc.surfaceView.appearance = appearance
    
    lsfpc.set(contentViewController: layerSelectPanelViewController)

    self.present(lsfpc, animated: true, completion: nil)
  }
  
  @objc func layersButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      let change = LayerManager.shared.magic()
      
      HUDManager.shared.displayMessage(message: .magic(change))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func offlineButtonTapped(sender: MapButton) {
    if presentedViewController != nil {
      let isMe = presentedViewController == osfpc
      presentedViewController!.dismiss(animated: isMe, completion: nil)
      
      if(isMe) {return}
    }
    
    let offlineSelectPanelViewController = OfflineSelectPanelViewController()
   
    osfpc.layout = offlineSelectPanelLayout
    osfpc.delegate = offlineSelectPanelViewController
    osfpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
    osfpc.isRemovalInteractionEnabled = true
    osfpc.contentMode = .fitToBounds
   
    let appearance = SurfaceAppearance()
//     appearance.cornerCurve = CALayerCornerCurve.continuous
    appearance.cornerRadius = 16
    appearance.backgroundColor = .clear
    osfpc.surfaceView.appearance = appearance
   
    osfpc.set(contentViewController: offlineSelectPanelViewController)

    self.present(osfpc, animated: true, completion: nil)
  }
  
  @objc func offlineButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      OfflineManager.shared.offlineMode = !OfflineManager.shared.offlineMode
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func appIconButtonTapped(sender: UIButton) {
    if presentedViewController != nil {
      let isMe = presentedViewController == abfpc
      presentedViewController!.dismiss(animated: isMe, completion: nil)
      
      if(isMe) {return}
    }

    let aboutPanelViewController = AboutPanelViewController()
    
    abfpc.layout = aboutPanelLayout
    abfpc.delegate = aboutPanelViewController
    abfpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
    abfpc.isRemovalInteractionEnabled = true
//    abfpc.contentMode = .fitToBounds
    
    let appearance = SurfaceAppearance()
//    appearance.cornerCurve = CALayerCornerCurve.continuous
    appearance.cornerRadius = 16
    appearance.backgroundColor = .clear
    abfpc.surfaceView.appearance = appearance
    
    abfpc.set(contentViewController: aboutPanelViewController)

    self.present(abfpc, animated: true, completion: nil)
  }
  
  @objc func twoFingerTapped() {
    let layer = LayerManager.shared.magicFavourite(forward: true)
    
    if(layer != nil) {
      HUDManager.shared.displayMessage(message: .layer(layer!))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func threeFingerTapped() {
    let layer = LayerManager.shared.magicFavourite(forward: false)
    
    if(layer != nil) {
      HUDManager.shared.displayMessage(message: .layer(layer!))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  static let shared = MapViewController()
}

protocol ParentMapViewRegionIsChangingDelegate {
  func parentMapViewRegionIsChanging()
}

protocol UserLocationDidUpdateDelegate {
  func userLocationDidUpdate()
}

protocol MapViewTappedDelegate {
  func mapViewTapped()
}
