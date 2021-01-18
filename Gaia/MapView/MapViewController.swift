import UIKit
import Mapbox
import FloatingPanel

class MapViewController: UIViewController, MGLMapViewDelegate{
  var layerManager: LayerManager?

  var mapView: MGLMapView!
  var rasterLayer: MGLRasterStyleLayer?
  var userLocationButton: UserLocationButton?
  let fpc = FloatingPanelController()
  
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

    mapView.tintColor = .systemBlue

    mapView.delegate = self

    view.addSubview(mapView)
    
    let userLocationButton = UserLocationButton(initialMode: mapView.userTrackingMode, tintColor: mapView.tintColor)
    userLocationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    userLocationButton.translatesAutoresizingMaskIntoConstraints = false
    self.userLocationButton = userLocationButton
    
    let layersButton = MapButton() ;
    layersButton.setImage(UIImage(systemName: "map"), for: .normal)
    layersButton.tintColor = mapView.tintColor
    layersButton.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)
    
    let testButton = MapButton() ;
    testButton.setImage(UIImage(systemName: "square.and.arrow.down.on.square"), for: .normal)
    testButton.tintColor = mapView.tintColor
    
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
    if fpc.viewIfLoaded?.window == nil {
      let popoverLayerSelectViewController = PopoverLayerSelectViewController(layerManager: layerManager!)
      
      fpc.layout = MapPopoverPanelLayout()
      fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = false
      
      let appearance = SurfaceAppearance()
  //    appearance.cornerCurve = CALayerCornerCurve.continuous
      appearance.cornerRadius = 16
      appearance.backgroundColor = .clear
      fpc.surfaceView.appearance = appearance
      
      fpc.set(contentViewController: popoverLayerSelectViewController)

      fpc.isRemovalInteractionEnabled = true
      
      fpc.track(scrollView: popoverLayerSelectViewController.layerSelectView)

      self.present(fpc, animated: true, completion: nil)
    } else {
      fpc.dismiss(animated: true, completion: nil)
    }
  }
  
}

class MapPopoverPanelLayout: FloatingPanelLayout {
  let position: FloatingPanelPosition = .bottom
  let initialState: FloatingPanelState = .half
  var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    return [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea),
        ]
  }
  
  func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
    return true
  }
  
  func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
    return 0
  }
}
