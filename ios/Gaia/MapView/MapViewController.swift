import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate, LayerManagerDelegate, OfflineModeDelegate, SettingsManagerDelegate, UIGestureRecognizerDelegate {
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
    mapView.compassViewPosition = SettingsManager.shared.rightHandedMenu.value ? .topRight : .topLeft
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
    
    let twoFingerLongPress = UILongPressGestureRecognizer(target: self, action: #selector(quickToggleLongPress))
    twoFingerLongPress.minimumPressDuration = 0.4
    twoFingerLongPress.numberOfTouchesRequired = 2
    mapView.addGestureRecognizer(twoFingerLongPress)
    
    let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(twoFingerTapped))
    twoFingerTap.numberOfTapsRequired = 1
    twoFingerTap.numberOfTouchesRequired = 2
    mapView.addGestureRecognizer(twoFingerTap)

    let threeFingerTap = UITapGestureRecognizer(target: self, action: #selector(threeFingerTapped))
    threeFingerTap.numberOfTapsRequired = 1
    threeFingerTap.numberOfTouchesRequired = 3
    mapView.addGestureRecognizer(threeFingerTap)
    
    let fingerUpDown = UILongPressGestureRecognizer(target: self, action: #selector(fingerUpDown))
    fingerUpDown.minimumPressDuration = 0
    fingerUpDown.numberOfTouchesRequired = 1
    fingerUpDown.delegate = self
    mapView.addGestureRecognizer(fingerUpDown)
    
    return mapView
  }()
  
  // fingerUpDown
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }
  
  var brightnessHold: BrightnessManager.Hold = .infinite(immortal: false)
  
  @objc func fingerUpDown(gesture: UILongPressGestureRecognizer) {
    if ProcessInfo.processInfo.isLowPowerModeEnabled,
       SettingsManager.shared.autoAdjustment.value {
      switch gesture.state {
        case .began: BrightnessManager.shared.place(hold: brightnessHold)
        case .ended: BrightnessManager.shared.place(hold: .finite()); BrightnessManager.shared.remove(hold: brightnessHold)
        default: ()
      }
    }
  }
  
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
    
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(quickToggleLongPress))
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
  
  var mapButtonGroupSideConstraint: NSLayoutConstraint?
  
  lazy var mapButtonGroup: MapButtonGroup = {
    let buttonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, offlineButton])
    
    view.addSubview(buttonGroup)
    
    buttonGroup.translatesAutoresizingMaskIntoConstraints = false
    buttonGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36 + 20).isActive = true
    setMapButtonGroupSide(right: SettingsManager.shared.rightHandedMenu.value, buttonGroup: buttonGroup)
    
    return buttonGroup
  }()
  
  func setMapButtonGroupSide(right: Bool, buttonGroup: MapButtonGroup? = nil){
    let buttonGroup = buttonGroup ?? mapButtonGroup
    mapButtonGroupSideConstraint?.isActive = false
    mapButtonGroupSideConstraint = right
      ? buttonGroup.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -6)
      : buttonGroup.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 6)
    
    mapButtonGroupSideConstraint?.isActive = true
  }
  
  lazy var appIconButton: AppIconButton = {
    let button = AppIconButton()
    
    view.addSubview(button)
    
    let (bottom, left) = (UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows.first!.safeAreaInsets.bottom > 0
      ? (10, 15)
      : (-6, 6)
    
    button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: CGFloat(bottom)).isActive = true
    button.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: CGFloat(left)).isActive = true
    
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
        let layersToShow = layers != nil && !layers!.isEmpty
          ? layers!
          : [
              LayerManager.shared.pinnedLayers.sorted(by: LayerManager.shared.layerSortingFunction).first(where: {$0.isOpaque})
                ?? LayerManager.shared.layers.first(where: {$0.isOpaque})
            ].compactMap({$0})
        
        if(!layersToShow.isEmpty) {
          LayerManager.shared.show(layers: layersToShow)
          HUDManager.shared.displayMessage(message: .noLayersWarningFixed)
        }
      case .minZoom(let minZoom):
        mapView.setZoomLevel(minZoom, animated: true)
        HUDManager.shared.displayMessage(message: .zoomWarningFixed)
      case .multipleOpaque(let top):
        LayerManager.shared.show(layer: top, mutuallyExclusive: true)
        HUDManager.shared.displayMessage(message: .multipleOpaqueWarningFixed)
      case .bounds(let superbound):
        mapView.setVisibleCoordinateBounds(superbound, sensible: true, minZoom: styleCachedConstraints?.zoomLevelsCovered.0, animated: true)
        HUDManager.shared.displayMessage(message: .boundsWarningFixed)
      case .zeroOpacity(let layer):
        layer.style = layer.style.with(layer.style.interfacedLayers.compactMap({$0.opacity == 0 ? $0.setting(.opacity, to: 1.0) : nil}))
        LayerManager.shared.save()
        HUDManager.shared.displayMessage(message: .zeroOpacityWarningFixed)
    }
  }
  
  var warnings: Set<WarningReason> = [] {
    didSet {
      if(oldValue != warnings) {
        print(warnings)
        
        UIView.animate(withDuration: 0.5, withCubicBezier: [0.33, 1.18, 0.23, 0.93]){
          self.warningButtonGroup.layer.opacity = self.warnings.isEmpty ? 0 : 1
          if(oldValue.count != self.warnings.count) {
            let foreground = UIImage(systemName: "\(self.warnings.count).circle.fill")!.withTintColor(.systemRed)
            self.warningIconCount.image = foreground.draw(inFrontOf: self.warningIconCountBackground)
          }
        }

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
          title = "Pan to Layer Area"
          systemName = "arrow.up.and.down.and.arrow.left.and.right"
        case .minZoom:
          title = "Zoom In"
          systemName = "plus.magnifyingglass"
        case .multipleOpaque:
          title = "Hide Obscured Layers"
          systemName = "square.stack.3d.up.slash"
        case .zeroOpacity:
          title = "Fix Fully Transparent Layer"
          systemName = "eye"
      }
      
      return UIAction(title: title, image: UIImage(systemName: systemName)) {(_) in self.resolve(warning: warning)}
    }))
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    LayerManager.shared.multicastCompositeStyleDidChangeDelegate.add(delegate: self)
    OfflineManager.shared.multicastOfflineModeDidChangeDelegate.add(delegate: self)
    SettingsManager.shared.multicastSettingManagerDelegate.add(delegate: self)
    
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
    
    if let location = userLocation?.location {
      let radius = location.horizontalAccuracy
      
      mapView.tintColor = radius >= 30 ? .systemPink : .systemBlue
    }
  }
  
  func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
    openLocationInfoPanel(location: .user)
    
    mapView.deselectAnnotation(annotation, animated: false)
  }
  
  lazy var mapViewRegionIsChangingCheck = Debounce(time: 0.1){
    self.checkZoomLevel()
    self.checkBounds()
  }

  func mapViewRegionIsChanging(_ mapView: MGLMapView) {
    multicastParentMapViewRegionIsChangingDelegate.invoke(invocation: {$0.parentMapViewRegionIsChanging()})
    
    if(!ProcessInfo.processInfo.isLowPowerModeEnabled){
      mapViewRegionIsChangingCheck.go()
    }
  }

  func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
    switch mode {
      case .followWithHeading, .followWithCourse:
        mapView.locationManager.startUpdatingHeading()
        mapView.locationManager.startUpdatingLocation()
        mapView.tintColor = .systemPink
      case .follow:
        mapView.resetNorth()
        mapView.locationManager.stopUpdatingHeading()
        mapView.locationManager.startUpdatingLocation()
        mapView.tintColor = .systemPink
      case .none:
        fallthrough
    @unknown default:
      mapView.resetNorth()
      mapView.locationManager.stopUpdatingHeading()
      
      if(ProcessInfo.processInfo.isLowPowerModeEnabled){
        mapView.locationManager.stopUpdatingLocation()
        mapView.tintColor = .systemGray
      }
    }

    userLocationButton.updateArrowForTrackingMode(mode: mode)
  }
  
  func compositeStyleDidChange(to: CompositeStyle, from: CompositeStyle?) {
    let style = to.toStyle()
    
    mapView.styleURL = style.url
    styleCachedConstraints = (style.zoomLevelsCovered, style.bounds)

    updateUIColourScheme(compositeStyle: to)
    reactToLayerChanges(to: to, from: from)
    
    if(!ProcessInfo.processInfo.isLowPowerModeEnabled){
      checkLayers(to: to, from: from)
      checkZoomLevel()
      checkBounds()
    }
    
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
    if(to.isEmpty && !LayerManager.shared.layers.isEmpty){
      warnings.insert(.emptyStyle(from?.sortedLayers))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .emptyStyle = $0 {return false}; return true})
    }
    
    if(to.hasMultipleOpaque){
      warnings.insert(.multipleOpaque(to.topOpaque!))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .multipleOpaque = $0 {return false}; return true})
    }
    
    if let layer = to.sortedLayers.first(where: {$0.style.opacity == 0}){
      warnings.insert(.zeroOpacity(layer))
    } else if(!warnings.isEmpty){
      warnings = warnings.filter({if case .zeroOpacity = $0 {return false}; return true})
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
    lifpc.behavior = DefaultPanelBehaviour()
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
    toggleLayerSelectPanel()
  }
  
  func toggleLayerSelectPanel(keepOpen: Bool = false) {
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
    lsfpc.behavior = DefaultPanelBehaviour()
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
  
  @objc func quickToggleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      let change = LayerManager.shared.quickToggle(bounds: mapView.visibleCoordinateBounds)
      
      if(change.count == 0) {
        return
      }
      
      HUDManager.shared.displayMessage(message: .quickToggle(change))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func offlineButtonTapped(sender: MapButton) {
    toggleOfflineSelectPanel()
  }
  
  func toggleOfflineSelectPanel(keepOpen: Bool = false) {
    if presentedViewController != nil {
      let isMe = presentedViewController == osfpc
      
      if(isMe){
        if(!keepOpen) {
          presentedViewController!.dismiss(animated: true, completion: nil)
        }
        
        return
      } else {
        presentedViewController!.dismiss(animated: false, completion: nil)
      }
    }

    let offlineSelectPanelViewController = OfflineSelectPanelViewController()
    
    osfpc.layout = offlineSelectPanelLayout
    osfpc.behavior = DefaultPanelBehaviour()
    osfpc.delegate = offlineSelectPanelViewController
    osfpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
    osfpc.isRemovalInteractionEnabled = true
    osfpc.contentMode = .fitToBounds
    
    let appearance = SurfaceAppearance()
//    appearance.cornerCurve = CALayerCornerCurve.continuous
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
    abfpc.behavior = DefaultPanelBehaviour()
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
      HUDManager.shared.displayMessage(message: .magicPinned(layer!))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  @objc func threeFingerTapped() {
    let layer = LayerManager.shared.magicPinned(forward: false)
    
    if(layer != nil) {
      HUDManager.shared.displayMessage(message: .magicPinned(layer!))
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
  
  func settingsDidChange() {
    mapView.compassViewPosition = SettingsManager.shared.rightHandedMenu.value ? .topRight : .topLeft
    setMapButtonGroupSide(right: SettingsManager.shared.rightHandedMenu.value)
  }
  
  override func didReceiveMemoryWarning() {
    InterfacedCache.shared.sources.removeAll()
    InterfacedCache.shared.layers.removeAll()
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
  case zeroOpacity(Layer)
}
