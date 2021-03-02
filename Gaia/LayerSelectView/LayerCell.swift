import Foundation
import UIKit
import CoreData

import Mapbox

class LayerCell: UITableViewCell, ParentMapViewRegionIsChangingDelegate {
  var _layer: Layer?
  
  var first = true
  var visible = false
  var queuedStyle: Style?
  var displayedStyle: Style?
  var needsUpdating = false
  
  var maximumZoomLevel: Double = 30
  var minimumZoomLevel: Double = 0
  
  var disabledCount: Int? {
    didSet {
      if(oldValue != disabledCount) {
        disabledCountDisplay.isHidden = disabledCount == nil
        disabledCountDisplay.text = "+" + String(disabledCount ?? 0)
      }
    }
  }

  let preview = MGLMapView(frame: CGRect.zero)
  let previewSpacing: CGFloat = 15
  let title = UILabel()
  
  lazy var height = contentView.heightAnchor.constraint(equalToConstant: 100)
  
  lazy var disabledCountDisplay: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 18, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 0
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    label.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
    
    return label
  }()
  
  var previewIsBlurred = false {
    didSet {
      if(oldValue != previewIsBlurred) {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(
          self.previewIsBlurred
            ? CAMediaTimingFunction(controlPoints: 0.83, 0.20, 0, 1.15)
            : CAMediaTimingFunction(controlPoints: 0.29, 0.93, 0, 0.92)
        )
        
        UIView.animate(withDuration: self.previewIsBlurred ? 0.5 : 0.4) {
          self.previewBlur.layer.opacity = self.previewIsBlurred ? 1 : 0
        }
        
        CATransaction.commit()
      }
    }
  }
  
  var previewBlurHack: UIViewPropertyAnimator?
  
  lazy var previewBlur: UIVisualEffectView = {
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    let visualEffectView = UIVisualEffectView(effect: nil)

    visualEffectView.frame = preview.bounds
    visualEffectView.backgroundColor = .clear
    visualEffectView.layer.opacity = 0
    
    previewBlurHack = UIViewPropertyAnimator(duration: 1, curve: .linear) {
      visualEffectView.effect = blurEffect
    }
    previewBlurHack!.fractionComplete = 0.1

    preview.addSubview(visualEffectView)
    
    let icon = UIImageView(image: UIImage(systemName: "plus.magnifyingglass"))
    icon.contentMode = .scaleAspectFit
    
    visualEffectView.contentView.addSubview(icon)
    
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.widthAnchor.constraint(equalTo: visualEffectView.widthAnchor, multiplier: 0.4).isActive = true
    icon.heightAnchor.constraint(equalTo: icon.widthAnchor).isActive = true
    icon.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor).isActive = true
    icon.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor).isActive = true
    
    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    visualEffectView.widthAnchor.constraint(equalTo: preview.widthAnchor).isActive = true
    visualEffectView.topAnchor.constraint(equalTo: preview.topAnchor).isActive = true
    visualEffectView.bottomAnchor.constraint(equalTo: preview.bottomAnchor).isActive = true
    visualEffectView.leftAnchor.constraint(equalTo: preview.leftAnchor).isActive = true
    
    return visualEffectView
  }()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    autoresizingMask = .flexibleHeight

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
  
  deinit {
    previewBlurHack?.stopAnimation(true)
  }

  func parentMapViewRegionIsChanging() {
    if(displayedStyle != nil && !(_layer?.enabled ?? false)){return}
    
    visible = self.isVisible()
    if(!visible){return}
    
    if(queuedStyle != displayedStyle) {
      displayedStyle = queuedStyle
      preview.styleURL = displayedStyle!.toURL()
      
      let (minZoom, maxZoom) = displayedStyle!.getVisibleZoomLevels()
      print((minZoom, maxZoom))
      
      maximumZoomLevel = maxZoom ?? 30
      minimumZoomLevel = minZoom ?? 0
    }
    
    let zoomLevel = MapViewController.shared.mapView.zoomLevel
    
    if(zoomLevel < minimumZoomLevel - 2){
      previewIsBlurred = true

      return
    } else {
      previewIsBlurred = false
    }
    
    let parent = MapViewController.shared.mapView.bounds
    let centerPoint = CGPoint(x: parent.width * 0.5, y: parent.height * 0.25)
    
    preview.setCenter(
      MapViewController.shared.mapView.convert(centerPoint, toCoordinateFrom: nil),
      zoomLevel: zoomLevel - 0.5,
      direction: MapViewController.shared.mapView.direction,
      animated: false
    )
    
    needsUpdating = false
  }

  func update(_layer: Layer, layerSelectConfig: LayerSelectConfig, scrollView: LayerSelectView, disabledCount: Int?) {
    self._layer = _layer
    self.disabledCount = disabledCount
 
    queuedStyle = _layer.style
    
    height.constant = _layer.enabled ? 100 : 80
    contentView.layer.opacity = _layer.enabled ? 1 : 0.5
    
    let mutuallyExclusive = layerSelectConfig.mutuallyExclusive
    backgroundColor = !mutuallyExclusive && _layer.visible
      ? .systemBlue
      : .clear
    
    tintColor = !mutuallyExclusive && _layer.visible
      ? .white
      : nil
    
    title.textColor = !mutuallyExclusive && _layer.visible
      ? .white
      : .label
    
    preview.tintColor = .white

    if(first) {
      self.first = false
      
      MapViewController.shared.multicastParentMapViewRegionIsChangingDelegate.add(delegate: self)
      scrollView.multicastScrollViewDidScrollDelegate.add(delegate: self)
    }

    title.text = _layer.name
    accessibilityLabel = title.text! + " Layer"

    accessoryType = _layer.visible ? .checkmark : .none

    DispatchQueue.main.async { // allow time for .isVisible() to return correct result
      self.needsUpdating = true
      self.parentMapViewRegionIsChanging()
    }
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}

extension LayerCell: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if(!visible || needsUpdating){
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
