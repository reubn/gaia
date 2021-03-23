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

  var firstTimeLocating = true
  
  var styleCachedConstraints: (zoomLevelsCovered: (Double, Double), bounds: Style.BoundsInfo)?

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

    let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
    for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
      singleTap.require(toFail: recognizer)
    }
    mapView.addGestureRecognizer(singleTap)

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
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
    let buttonGroup = MapButtonGroup(arrangedSubviews: [warningButton])
    
    view.addSubview(buttonGroup)
    
    buttonGroup.translatesAutoresizingMaskIntoConstraints = false
    buttonGroup.leftAnchor.constraint(equalTo: mapButtonGroup.leftAnchor).isActive = true
    buttonGroup.topAnchor.constraint(equalTo: mapButtonGroup.bottomAnchor, constant: 6).isActive = true
    
    return buttonGroup
  }()
  
  lazy var warningIconCountBackground = UIImage(systemName: "circle.fill")!.withTintColor(.white)
  lazy var warningIconCount: UIImageView = {
    let imageView = UIImageView(image: nil)
    let size: CGFloat = 15

    warningButton.addSubview(imageView)
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    
    imageView.centerXAnchor.constraint(equalTo: warningButton.centerXAnchor, constant: (size / 2) + 3).isActive = true
    imageView.centerYAnchor.constraint(equalTo: warningButton.centerYAnchor, constant: size / 2).isActive = true
    
    return imageView
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
    
    button.addTarget(self, action: #selector(warningButtonTapped), for: .touchUpInside)
    
    return button
  }()
  
  @objc func warningButtonTapped(){
    if(warnings.isEmpty) {
      return
    }
    
    // this could be better
    let biggestResolver = warnings.first(where: {if case .multipleOpaque = $0 {return true}; return false}) ?? warnings.randomElement()!
    
    resolve(warning: biggestResolver)
  }
  
  func resolve(warning: WarningReason){
    switch warning {
      case .emptyStyle(let layers):
        if(layers != nil) {
          LayerManager.shared.filterLayers({layers!.contains($0)})
          
          HUDManager.shared.displayMessage(message: .noLayersWarningFixed)
        }
      case .minZoom(let minZoom):
        mapView.setZoomLevel(minZoom, animated: true)
        HUDManager.shared.displayMessage(message: .zoomWarningFixed)
      case .multipleOpaque(let top):
        LayerManager.shared.enableLayer(layer: top, mutuallyExclusive: true)
        HUDManager.shared.displayMessage(message: .multipleOpaqueWarningFixed)
      case .bounds(let superbound):
        mapView.setVisibleCoordinateBounds(superbound, sensible: true, minZoom: styleCachedConstraints?.zoomLevelsCovered.0, animated: true)
        HUDManager.shared.displayMessage(message: .boundsWarningFixed)
    }
  }
  
  var warnings: Set<WarningReason> = [] {
    didSet {
      if(oldValue != warnings) {
        print(warnings)
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.33, 1.18, 0.23, 0.93))
        
        UIView.animate(withDuration: 0.5){
          self.warningButtonGroup.layer.opacity = self.warnings.isEmpty ? 0 : 1
          if(oldValue.count != self.warnings.count) {
            let foreground = UIImage(systemName: "\(self.warnings.count).circle.fill")!.withTintColor(.systemRed)
            self.warningIconCount.image = foreground.draw(inFrontOf: self.warningIconCountBackground)
          }
        }
        
        CATransaction.commit()
        
        if(!warnings.isEmpty) {
          self.warningButton.menu = createMenu(warnings: warnings)
        }
      }
    }
  }
  
  func createMenu(warnings: Set<WarningReason>) -> UIMenu {
    UIMenu(options: .displayInline, children: warnings.map({
      let warning = $0
      
      let title: String
      let systemName: String
      
      switch warning {
        case .emptyStyle(let layers):
          title = "Restore \(layers?.first?.name ?? "Layers")"
          systemName = "square.stack.3d.up.fill"
        case .bounds:
          title = "Pan to Supported Area"
          systemName = "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"
        case .minZoom:
          title = "Zoom to Supported Level"
          systemName = "arrow.up.left.and.down.right.magnifyingglass"
        case .multipleOpaque:
          title = "Hide Invisible Layers"
          systemName = "square.3.stack.3d.top.fill"
      }
      
      return UIAction(title: title, image: UIImage(systemName: systemName)) {(_) in self.resolve(warning: warning)}
    }))
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    
    _ = mapView
    _ = canvasView
        compass()
    _ = mapButtonGroup
    _ = appIconButton
    
    compositeStyleDidChange(to: LayerManager.shared.compositeStyle, from: nil)
    mapViewRegionIsChanging(mapView)
  }
  
  @objc func singleTapped(){
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
    checkBounds()
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
  
  func compositeStyleDidChange(to: CompositeStyle, from: CompositeStyle?) {
    mapView.styleURL = to.url
    styleCachedConstraints = (to.style.zoomLevelsCovered, to.style.bounds)

    updateUIColourScheme(compositeStyle: to)
    reactToLayerChanges(to: to, from: from)
    
    checkLayers(to: to, from: from)
    checkZoomLevel()
    checkBounds()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // needs greater delay than async
      self.multicastMapViewStyleDidChangeDelegate.invoke(invocation: {$0.styleDidChange()})
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
  
  func reactToLayerChanges(to: CompositeStyle, from: CompositeStyle?){
    if(from != nil){
      let difference = to.sortedLayers.difference(from: from!.sortedLayers)
      let insertions = difference.insertions
      
      if insertions.count == 1,
         case .insert(_, let layer, _) = insertions.first!,
         layer.style.bounds.superbound != nil {
        mapView.setVisibleCoordinateBounds(layer.style.bounds.superbound!, sensible: true, minZoom: styleCachedConstraints?.zoomLevelsCovered.0, animated: true)
      }
    }
  }

  func checkLayers(to: CompositeStyle, from: CompositeStyle?){
    if(to.isEmpty){
      warnings.insert(.emptyStyle(from?.sortedLayers))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .emptyStyle = $0 {return false}; return true})
    }
    
    if(to.hasMultipleOpaque){
      warnings.insert(.multipleOpaque(to.topNonOverlay!))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .multipleOpaque = $0 {return false}; return true})
    }
  }
  
  func checkZoomLevel(){
    let (minimumZoom, _) = styleCachedConstraints!.zoomLevelsCovered
    if(mapView.zoomLevel < minimumZoom - 2.5){
      warnings.insert(.minZoom(minimumZoom))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .minZoom = $0 {return false}; return true})
    }
  }
  
  func checkBounds(){
    let allBounds = styleCachedConstraints!.bounds.individual
    let showingLayerWithinBounds = allBounds.isEmpty || allBounds.contains(where: {$0.intersects(with: mapView.visibleCoordinateBounds)})

    if(!showingLayerWithinBounds){
      let superbound = styleCachedConstraints!.bounds.superbound!
      warnings.insert(.bounds(superbound))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .bounds = $0 {return false}; return true})
    }
  }

  func offlineModeDidChange(offline: Bool){
    offlineButton.setImage(offline ? UIImage(systemName: "icloud.slash.fill") : UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
  }
  
  @objc func longPressed(gestureReconizer: UILongPressGestureRecognizer){
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

protocol MapViewStyleDidChangeDelegate {
  func styleDidChange()
}

enum WarningReason: Equatable, Hashable {
  case minZoom(Double)
  case bounds(MGLCoordinateBounds)
  
  case emptyStyle([Layer]?)
  case multipleOpaque(Layer)
}
