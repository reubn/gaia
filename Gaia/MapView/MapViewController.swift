import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate, LayerManagerDelegate, OfflineModeDelegate {
  let lsfpc = MemoryConsciousFloatingPanelController()
  let osfpc = MemoryConsciousFloatingPanelController()
  let lifpc = MemoryConsciousFloatingPanelController()
  let abfpc = MemoryConsciousFloatingPanelController()
  
  let multicastParentMapViewRegionIsChangingDelegate = MulticastDelegate<(ParentMapViewRegionIsChangingDelegate)>()
  let multicastUserLocationDidUpdateDelegate = MulticastDelegate<(UserLocationDidUpdateDelegate)>()
  let multicastMapViewTappedDelegate = MulticastDelegate<(MapViewTappedDelegate)>()
  let multicastMapViewStyleDidChangeDelegate = MulticastDelegate<(MapViewStyleDidChangeDelegate)>()

//  var rasterLayer: MGLRasterStyleLayer?
  var firstTimeLocating = true

  lazy var mapView: MGLMapView = {
    let mapView = MGLMapView(frame: view.bounds)

    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mapView.logoView.isHidden = true
    mapView.attributionButton.isHidden = true
    
    mapView.userTrackingMode = .followWithHeading
    mapView.compassView.compassVisibility = .visible
    mapView.zoomLevel = 11
    
    mapView.tintColor = .systemBlue // user location should always be blue

    mapView.delegate = self
    
    view.addSubview(mapView)

    let singleTapGR = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
    for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
      singleTapGR.require(toFail: recognizer)
    }
    mapView.addGestureRecognizer(singleTapGR)

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPress))
    longPress.numberOfTouchesRequired = 1
    mapView.addGestureRecognizer(longPress)
    
    let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(twoFingerTapped))
    twoFingerTap.numberOfTapsRequired = 1
    twoFingerTap.numberOfTouchesRequired = 2
    mapView.addGestureRecognizer(twoFingerTap)

    let threeFingerTap = UITapGestureRecognizer(target: self, action: #selector(threeFingerTapped))
    threeFingerTap.numberOfTapsRequired = 1
    threeFingerTap.numberOfTouchesRequired = 3
    mapView.addGestureRecognizer(threeFingerTap)
    
    return mapView
  }()
  
  lazy var canvasView: CanvasView = {
    let canvasView = CanvasView(frame: mapView.frame)
    
    view.insertSubview(canvasView, belowSubview: mapView)
    
    return canvasView
  }()
  
  lazy var userLocationButton: UserLocationButton = {
    let userLocationButton = UserLocationButton(initialMode: mapView.userTrackingMode)
    userLocationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    userLocationButton.translatesAutoresizingMaskIntoConstraints = false
    userLocationButton.accessibilityLabel = "Change Tracking Mode"
    
    let userLocationButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(locationButtonLongPressed))
    userLocationButtonLongGR.minimumPressDuration = 0.4
    userLocationButton.addGestureRecognizer(userLocationButtonLongGR)
    
    return userLocationButton
  }()
  
  lazy var layersButton: MapButton = {
    let button = MapButton()
    button.setImage(UIImage(systemName: "map"), for: .normal)
    button.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
    button.accessibilityLabel = "Layers"
    
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(layersButtonLongPressed))
    longPress.minimumPressDuration = 0.4
    button.addGestureRecognizer(longPress)
    
    return button
  }()
  
  lazy var offlineButton: MapButton = {
    let button = MapButton()
    button.setImage(
      OfflineManager.shared.offlineMode
        ? UIImage(systemName: "icloud.slash.fill")
        : UIImage(systemName: "square.and.arrow.down.on.square"
    ), for: .normal)
    button.addTarget(self, action: #selector(offlineButtonTapped), for: .touchUpInside)
    button.accessibilityLabel = "Downloads"
    
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(offlineButtonLongPressed))
    longPress.minimumPressDuration = 0.4
    button.addGestureRecognizer(longPress)
    
    return button
  }()
  
  lazy var mapButtonGroup: MapButtonGroup = {
    let buttonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, offlineButton])
    
    view.addSubview(buttonGroup)
    
    buttonGroup.translatesAutoresizingMaskIntoConstraints = false
    buttonGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36 + 20).isActive = true
    buttonGroup.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -6).isActive = true
    
    return buttonGroup
  }()
  
  lazy var appIconButton: AppIconButton = {
    let button = AppIconButton()
    
    view.addSubview(button)
    
    button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10).isActive = true
    button.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
    
    button.addTarget(self, action: #selector(appIconButtonTapped), for: .touchUpInside)
    button.accessibilityLabel = "About"
    
    return button
  }()

  lazy var warningButtonGroup: MapButtonGroup = {
    let mapButtonGroup = MapButtonGroup(arrangedSubviews: [warningButton])
    
    view.addSubview(mapButtonGroup)
    
    mapButtonGroup.translatesAutoresizingMaskIntoConstraints = false
    mapButtonGroup.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 6).isActive = true
    mapButtonGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6).isActive = true
    
    return mapButtonGroup
  }()
  
  lazy var warningButton: MapButton = {
    let button = MapButton()
    button.setImage(UIImage(systemName: "exclamationmark.triangle.fill"), for: .normal)
    
    let inset: CGFloat = 10
    button.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    button.imageView!.contentMode = .scaleAspectFit
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    
    button.tintColor = .systemYellow
    button.accessibilityLabel = "Warning"
    
    return button
  }()
  
  var warnings: Set<WarningReason> = [] {
    didSet {
      if(oldValue != warnings) {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.33, 1.18, 0.23, 0.93))
        
        UIView.animate(withDuration: 0.5){
          self.warningButtonGroup.layer.opacity = self.warnings.isEmpty ? 0 : 1
        }
        
        CATransaction.commit()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    setUpCompass()
    _ = mapButtonGroup
    _ = appIconButton
    
    compositeStyleDidChange(compositeStyle: LayerManager.shared.compositeStyle)
    mapViewRegionIsChanging(mapView)
  }
  
  func checkZoomLevel(){
    let (minimumZoom, _) = LayerManager.shared.compositeStyle.style.visibleZoomLevels
    if(mapView.zoomLevel < minimumZoom - 2.5){
      warnings.insert(.minZoom)
    } else {
      warnings.remove(.minZoom)
    }
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
    
    checkZoomLevel()
  }

  func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
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
  
    if(compositeStyle.isEmpty){
      warnings.insert(.emptyStyle)
    } else {
      warnings.remove(.emptyStyle)
    }
    
    if(compositeStyle.hasMultipleOpaque){
      warnings.insert(.multipleOpaque)
    } else {
      warnings.remove(.multipleOpaque)
    }
    
    checkZoomLevel()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // needs greater delay than async
      self.multicastMapViewStyleDidChangeDelegate.invoke(invocation: {$0.compositeStyleDidChange(compositeStyle: compositeStyle)})
    }
  }
  
  func updateUIColourScheme(compositeStyle: CompositeStyle){
    let uiColourTint: UIColor = .systemBlue
    
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
    openLayerSelectPanel()
  }
  
  func openLayerSelectPanel(keepOpen: Bool = false) {
    if presentedViewController != nil {
      let isMe = presentedViewController == lsfpc
      
      if(isMe){
        if(!keepOpen) {
          presentedViewController!.dismiss(animated: true, completion: nil)
        }
        
        return
      } else {
        presentedViewController!.dismiss(animated: false, completion: nil)
      }
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
    let layer = LayerManager.shared.magicPinned(forward: true)
    
    if(layer != nil) {
      HUDManager.shared.displayMessage(message: .layer(layer!))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func threeFingerTapped() {
    let layer = LayerManager.shared.magicPinned(forward: false)
    
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

typealias MapViewStyleDidChangeDelegate = LayerManagerDelegate

enum WarningReason: Equatable {
  case minZoom
  case maxZoom
  
  case emptyStyle
  case multipleOpaque
}
