import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate {
  var layerManager: LayerManager?

  var mapView: MGLMapView!
  var rasterLayer: MGLRasterStyleLayer?
  var userLocationButton: UserLocationButton?
  var firstTimeLocating = true
  let lsfpc = FloatingPanelController()
  let omfpc = FloatingPanelController()

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView = MGLMapView(frame: view.bounds)
    layerManager = LayerManager(mapView: mapView)
    layerManager!.apply()

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

    let layersButton = MapButton() ;
    layersButton.setImage(UIImage(systemName: "map"), for: .normal)
    layersButton.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
    layersButton.addTarget(self, action: #selector(layersButtonLongPressed), for: .touchDownRepeat)
    
    let layersButtonLongGR = UILongPressGestureRecognizer(target: self, action: #selector(layersButtonLongPressed))
    layersButtonLongGR.minimumPressDuration = 0.4
    layersButton.addGestureRecognizer(layersButtonLongGR)

    let testButton = MapButton() ;
    testButton.setImage(UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)

    let mapButtonGroup = MapButtonGroup(arrangedSubviews: [userLocationButton, layersButton, testButton])

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
    layerManager!.multicastMapViewRegionIsChangingDelegate.invoke(invocation: {$0.mainMapViewRegionIsChanging()})
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

  @IBAction func locationButtonTapped(sender: UserLocationButton) {
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

  @IBAction func layersButtonTapped(sender: MapButton) {
    if lsfpc.viewIfLoaded?.window == nil {
      let layerSelectPanelViewController = LayerSelectPanelViewController(layerManager: layerManager!)
      
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
  
  @IBAction func layersButtonLongPressed(gestureReconizer: UILongPressGestureRecognizer) {
    if gestureReconizer.state == UIGestureRecognizer.State.began {
      layerManager!.magic()
      
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }
}
