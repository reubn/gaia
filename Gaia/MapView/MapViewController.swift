import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate, LayerManagerDelegate, OfflineModeDelegate {
  let layerManager = LayerManager()
  let offlineManager = OfflineManager()

  var mapView: MGLMapView!
  var rasterLayer: MGLRasterStyleLayer?
  var userLocationButton: UserLocationButton?
  var firstTimeLocating = true
  let lsfpc = FloatingPanelController()
  let osfpc = FloatingPanelController()
  
  let layersButton = MapButton()
  let offlineButton = MapButton()
  
  let uiColourTint: UIColor = .systemBlue
  
  let multicastParentMapViewRegionIsChangingDelegate = MulticastDelegate<(LayerCell)>()

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
    
    mapView.tintColor = .systemBlue // user location should always be blue

    mapView.delegate = self

    view.addSubview(mapView)

    let userLocationButton = UserLocationButton(initialMode: mapView.userTrackingMode)
    userLocationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    userLocationButton.translatesAutoresizingMaskIntoConstraints = false
    self.userLocationButton = userLocationButton

    layersButton.setImage(UIImage(systemName: "map"), for: .normal)
    layersButton.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
//    layersButton.addTarget(self, action: #selector(layersButtonLongPressed), for: .touchDownRepeat)
    
    let layersButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(layersButtonLongPressed))
    layersButtonLongGR.minimumPressDuration = 0.4
    layersButton.addGestureRecognizer(layersButtonLongGR)

    offlineButton.setImage(offlineManager.offlineMode ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
    offlineButton.addTarget(self, action: #selector(offlineButtonTapped), for: .touchUpInside)
    
    let offlineButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(offlineButtonLongPressed))
    offlineButtonLongGR.minimumPressDuration = 0.4
    offlineButton.addGestureRecognizer(offlineButtonLongGR)
    
    let mapButtonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, offlineButton])

    let constraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(
        item: mapButtonGroup,
        attribute: .top,
        relatedBy: .greaterThanOrEqual,
        toItem: view.safeAreaLayoutGuide,
        attribute: .top,
        multiplier: 1,
        constant: 36 + 20
      ),
      NSLayoutConstraint(
        item: mapButtonGroup,
        attribute: .trailing,
        relatedBy: .equal,
        toItem: view.safeAreaLayoutGuide,
        attribute: .trailing,
        multiplier: 1,
        constant: -6
      )
    ]

    view.addSubview(mapButtonGroup)
    view.addConstraints(constraints)
  }
  
  func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?){
    if(firstTimeLocating && userLocation?.location != nil) {
      mapView.centerCoordinate = userLocation!.location!.coordinate
      mapView.userTrackingMode = .followWithHeading
      firstTimeLocating = false
    }
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
    }
  }
  
  func offlineModeDidChange(offline: Bool){
//    offlineButton.tintColor = offline ? .systemPink : mapView.window?.tintColor
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

  @objc func layersButtonTapped(sender: MapButton) {
    if osfpc.viewIfLoaded?.window != nil {
      osfpc.dismiss(animated: false, completion: nil)
    }
    
    if lsfpc.viewIfLoaded?.window == nil {
      let layerSelectPanelViewController = LayerSelectPanelViewController(mapViewController: self)
      
      lsfpc.layout = LayerSelectPanelLayout()
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

//      fpc.track(scrollView: popoverLayerSelectViewController.rootScrollView)

      self.present(lsfpc, animated: true, completion: nil)
    } else {
      lsfpc.dismiss(animated: true, completion: nil)
    }
  }
  
  @objc func layersButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      layerManager.magic()
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func offlineButtonTapped(sender: MapButton) {
    if lsfpc.viewIfLoaded?.window != nil {
      lsfpc.dismiss(animated: false, completion: nil)
    }
    
    if osfpc.viewIfLoaded?.window == nil {
      let offlineSelectPanelViewController = OfflineSelectPanelViewController(mapViewController: self)
     
      osfpc.layout = OfflineSelectPanelLayout()
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

  //       fpc.track(scrollView: popoverLayerSelectViewController.rootScrollView)

      self.present(osfpc, animated: true, completion: nil)
    } else {
      osfpc.dismiss(animated: true, completion: nil)
    }
  }
  
  @objc func offlineButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      offlineManager.offlineMode = !offlineManager.offlineMode
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
}
