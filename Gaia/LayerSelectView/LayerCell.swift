import Foundation
import UIKit
import CoreData

import Mapbox

class LayerCell: UITableViewCell, ParentMapViewRegionIsChangingDelegate {
  var _layer: Layer?
  var layerManager: LayerManager?
  var mapViewController: MapViewController?
  var first = true
  var active = false

  let preview = MGLMapView(frame: CGRect.zero)
  let previewSpacing:CGFloat = 15
  let title = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    autoresizingMask = .flexibleHeight
    let height = contentView.heightAnchor.constraint(equalToConstant: 100)
    height.priority = UILayoutPriority(rawValue: 999)
    height.isActive = true

    contentView.backgroundColor = UIColor.clear
    backgroundColor = UIColor.clear

    preview.layer.cornerRadius = 10
    preview.layer.cornerCurve = .continuous
    preview.clipsToBounds = true
    preview.backgroundColor = .black
    preview.layer.allowsEdgeAntialiasing = true

    preview.allowsScrolling = false
    preview.allowsTilting = false
    preview.allowsZooming = false
    preview.allowsRotating = false
    preview.compassView.isHidden = true
    preview.showsUserLocation = false
    preview.showsUserHeadingIndicator = false

    preview.logoView.isHidden = true
    preview.attributionButton.isHidden = true

    contentView.addSubview(preview)

    preview.translatesAutoresizingMaskIntoConstraints = false
    preview.widthAnchor.constraint(equalTo: preview.heightAnchor).isActive = true
    preview.topAnchor.constraint(equalTo: contentView.topAnchor, constant: previewSpacing).isActive = true
    preview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -previewSpacing).isActive = true
    preview.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: previewSpacing).isActive = true

    title.font = UIFont.systemFont(ofSize: 18)
    title.textColor = UIColor.label
    title.numberOfLines = 0

    contentView.addSubview(title)

    title.translatesAutoresizingMaskIntoConstraints = false
    title.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    title.leftAnchor.constraint(equalTo: preview.rightAnchor, constant: previewSpacing).isActive = true
    title.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
  }

  func parentMapViewRegionIsChanging() {
    active = self.isVisible()
    if(!active){return}
    
    let parent = mapViewController!.mapView.bounds
    let centerPoint = CGPoint(x: parent.width * 0.5, y: parent.height * 0.25)
    
    preview.setCenter(
      mapViewController!.mapView.convert(centerPoint, toCoordinateFrom: nil),
      zoomLevel: mapViewController!.mapView.zoomLevel - 0.5,
      direction: mapViewController!.mapView.direction,
      animated: false
    )
  }

  func update(_layer: Layer, layerSelectConfig: LayerSelectConfig, layerManager: LayerManager, mapViewController: MapViewController, scrollView: LayerSelectView) {
    self._layer = _layer
    self.layerManager = layerManager
    self.mapViewController = mapViewController

    preview.styleURL = CompositeStyle(sortedLayers: [_layer]).url
    
    let mutuallyExclusive = layerSelectConfig.mutuallyExclusive
    backgroundColor = !mutuallyExclusive && _layer.enabled ? .systemBlue : .clear
    tintColor = !mutuallyExclusive && _layer.enabled ? .white : nil
    title.textColor = !mutuallyExclusive && _layer.enabled ? .white : UIColor.label

    if(first) {
      mapViewController.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
      scrollView.multicastScrollViewDidScrollDelegate.add(delegate: self)
      parentMapViewRegionIsChanging()
      self.first = false
    }

    title.text = _layer.name

    accessoryType = _layer.enabled ? .checkmark : .none
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}

extension LayerCell: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if(!active){
      parentMapViewRegionIsChanging()
    }
  }
}

// https://stackoverflow.com/a/34641936
extension UIView {
  func isVisible() -> Bool {
    return UIView.isVisible(view: self, inView: superview)
  }
  
  static func isVisible(view: UIView, inView: UIView?) -> Bool {
    guard let inView = inView else { return true }
    let viewFrame = inView.convert(view.bounds, from: view)

    return viewFrame.intersects(inView.bounds) ? isVisible(view: view, inView: inView.superview) : false
  }
}
