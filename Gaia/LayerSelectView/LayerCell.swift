import Foundation
import UIKit
import CoreData

import Mapbox

class LayerCell: UITableViewCell, ParentMapViewRegionIsChangingDelegate {
  var _layer: Layer?
  var layerManager: LayerManager?
  var mapViewController: MapViewController?
  var first = true

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
    contentView.addSubview(title)

    title.translatesAutoresizingMaskIntoConstraints = false
    title.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    title.leftAnchor.constraint(equalTo: preview.rightAnchor, constant: previewSpacing).isActive = true
  }

  func parentMapViewRegionIsChanging() {
    preview.setCenter(mapViewController!.mapView.centerCoordinate, zoomLevel: mapViewController!.mapView.zoomLevel - 2, animated: false)
  }

  func update(_layer: Layer, layerManager: LayerManager, mapViewController: MapViewController) {
    self._layer = _layer
    self.layerManager = layerManager
    self.mapViewController = mapViewController

    preview.styleURL = Style(sortedLayers: [_layer]).url

    if(first) {
      mapViewController.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
      preview.setCenter(mapViewController.mapView.centerCoordinate, zoomLevel: mapViewController.mapView.zoomLevel - 2, animated: false)
      self.first = false
    }

    title.text = _layer.name

    accessoryType = _layer.enabled ? .checkmark : .none
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}
