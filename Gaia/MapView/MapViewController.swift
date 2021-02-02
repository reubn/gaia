import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate, LayerManagerDelegate, OfflineModeDelegate {
  let layerManager = LayerManager()
  let offlineManager = OfflineManager()
  
  let lsfpc = MemoryConsciousFloatingPanelController()
  let osfpc = MemoryConsciousFloatingPanelController()
  let lifpc = MemoryConsciousFloatingPanelController()
  
  let layersButton = MapButton()
  let infoButton = MapButton()
  let offlineButton = MapButton()
  
  let uiColourTint: UIColor = .systemBlue
  
  let multicastParentMapViewRegionIsChangingDelegate = MulticastDelegate<(ParentMapViewRegionIsChangingDelegate)>()
  let multicastUserLocationDidUpdateDelegate = MulticastDelegate<(UserLocationDidUpdateDelegate)>()

  var mapView: MGLMapView!
  var rasterLayer: MGLRasterStyleLayer?
  var userLocationButton: UserLocationButton?
  var firstTimeLocating = true
  
  override func viewDidLoad() {
    super.viewDidLoad()

    mapView = MGLMapView(frame: view.bounds)
    layerManager.multicastStyleDidChangeDelegate.add(delegate: self)
    offlineManager.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    let initialStyle = layerManager.style
    mapView.styleURL = initialStyle.url
    updateUIColourScheme(style: initialStyle)

    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mapView.logoView.isHidden = true
    mapView.attributionButton.isHidden = true
    
    mapView.userTrackingMode = .followWithHeading
    mapView.compassView.compassVisibility = .visible
    mapView.zoomLevel = 11
    
    setUpCompass()

    mapView.tintColor = .systemBlue // user location should always be blue

    mapView.delegate = self

    view.addSubview(mapView)

    let userLocationButton = UserLocationButton(initialMode: mapView.userTrackingMode)
    userLocationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    userLocationButton.translatesAutoresizingMaskIntoConstraints = false
    self.userLocationButton = userLocationButton
    
    let userLocationButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(locationButtonLongPressed))
    userLocationButtonLongGR.minimumPressDuration = 0.4
    userLocationButton.addGestureRecognizer(userLocationButtonLongGR)

    layersButton.setImage(UIImage(systemName: "map"), for: .normal)
    layersButton.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
    
    let layersButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(layersButtonLongPressed))
    layersButtonLongGR.minimumPressDuration = 0.4
    layersButton.addGestureRecognizer(layersButtonLongGR)
    
    offlineButton.setImage(offlineManager.offlineMode ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
    offlineButton.addTarget(self, action: #selector(offlineButtonTapped), for: .touchUpInside)
    
    let offlineButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(offlineButtonLongPressed))
    offlineButtonLongGR.minimumPressDuration = 0.4
    offlineButton.addGestureRecognizer(offlineButtonLongGR)
    
    let mapButtonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, offlineButton])

    view.addSubview(mapButtonGroup)
    
    mapButtonGroup.translatesAutoresizingMaskIntoConstraints = false
    mapButtonGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36 + 20).isActive = true
    mapButtonGroup.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -6).isActive = true
  }
  
  func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?){
    multicastUserLocationDidUpdateDelegate.invoke(invocation: {$0.userLocationDidUpdate()})
    
    if(firstTimeLocating && userLocation?.location != nil) {
      mapView.centerCoordinate = userLocation!.location!.coordinate
      mapView.userTrackingMode = .followWithHeading
      firstTimeLocating = false
    }
  }
  
  func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
    openLocationInfoPanel()
    
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
  
  func styleDidChange(style: Style) {
    mapView.styleURL = style.url
    updateUIColourScheme(style: style)
  }
  
  func updateUIColourScheme(style: Style){
    DispatchQueue.main.async { [self] in
      let dark = style.needsDarkUI
      mapView.window?.overrideUserInterfaceStyle = dark ? .dark : .light
      mapView.window?.tintColor = dark ? .white : uiColourTint
      mapView.compassView.image = compassImage(dark: dark)
    }
  }
  
  func offlineModeDidChange(offline: Bool){
    offlineButton.setImage(offline ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
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
      openLocationInfoPanel()
    }
  }
  
  func openLocationInfoPanel() {
    if presentedViewController != nil {
      let isMe = presentedViewController == lifpc
      presentedViewController!.dismiss(animated: false, completion: nil)
      
      if(isMe) {return}
    }

    let locationInfoPanelViewController = LocationInfoPanelViewController(mapViewController: self)
    
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
      presentedViewController!.dismiss(animated: false, completion: nil)
      
      if(isMe) {return}
    }

    let layerSelectPanelViewController = LayerSelectPanelViewController(mapViewController: self)
    
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
      layerManager.magic()
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func offlineButtonTapped(sender: MapButton) {
    if presentedViewController != nil {
      let isMe = presentedViewController == osfpc
      presentedViewController!.dismiss(animated: false, completion: nil)
      
      if(isMe) {return}
    }
    
    let offlineSelectPanelViewController = OfflineSelectPanelViewController(mapViewController: self)
   
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
      offlineManager.offlineMode = !offlineManager.offlineMode
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
}

protocol ParentMapViewRegionIsChangingDelegate {
  func parentMapViewRegionIsChanging()
}

protocol UserLocationDidUpdateDelegate {
  func userLocationDidUpdate()
}


