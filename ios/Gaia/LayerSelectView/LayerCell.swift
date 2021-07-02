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
  
  var styleCachedConstraints: (zoomLevelsCovered: (Double, Double), bounds: Style.BoundsInfo)?
  
  var accessory: LayerCellAccessory? {
    didSet {
      if(oldValue != accessory) {
        switch accessory {
        case .normal, .none:
          disabledCountDisplay.isHidden = true
          disabledCountDisplay.text = ""
        case .plus(let count):
          disabledCountDisplay.isHidden = false
          disabledCountDisplay.text = "+" + String(count)
        case .collapse:
          disabledCountDisplay.isHidden = false
          
          let imageAttachment = NSTextAttachment()
          imageAttachment.image = UIImage(systemName: "chevron.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))?.withTintColor(.label)
          
          disabledCountDisplay.attributedText = NSAttributedString(attachment: imageAttachment)
        }
      }
    }
  }

  let preview = MGLMapView(frame: CGRect.zero)
  let previewSpacing: CGFloat = 15
  let title = UILabel()
  
  lazy var canvasView = CanvasView(frame: preview.frame, size: 10)
  
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

  var previewBlurReasons: [PreviewBlurReason] = [] {
    didSet {
      if(oldValue != previewBlurReasons) {
        let duration = !self.previewBlurReasons.isEmpty ? 0.5 : 0.4
        let cubicBezier: [Float] = !self.previewBlurReasons.isEmpty ? [0.83, 0.20, 0, 1.15] : [0.29, 0.93, 0, 0.92]
        
        UIView.animate(withDuration: duration, withCubicBezier: cubicBezier) {
          self.previewBlur.layer.opacity = !self.previewBlurReasons.isEmpty ? 1 : 0
          self.previewBlurIcon.image = {
            switch self.previewBlurReasons.first {
              case .bounds: return UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")
              case .minZoom: return UIImage(systemName: "plus.magnifyingglass")
              case .none: return nil
            }
          }()
        }
      }
    }
  }
  
  var previewBlurHack: UIViewPropertyAnimator?
  
  lazy var previewBlurIcon: UIImageView = UIImageView(image: nil)
  
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
    
    previewBlurIcon.contentMode = .scaleAspectFit
    
    visualEffectView.contentView.addSubview(previewBlurIcon)
    
    previewBlurIcon.translatesAutoresizingMaskIntoConstraints = false
    previewBlurIcon.widthAnchor.constraint(equalTo: visualEffectView.widthAnchor, multiplier: 0.4).isActive = true
    previewBlurIcon.heightAnchor.constraint(equalTo: previewBlurIcon.widthAnchor).isActive = true
    previewBlurIcon.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor).isActive = true
    previewBlurIcon.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor).isActive = true
    
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
    
    preview.insertSubview(canvasView, at: 0)
    
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    canvasView.topAnchor.constraint(equalTo: preview.topAnchor).isActive = true
    canvasView.leftAnchor.constraint(equalTo: preview.leftAnchor).isActive = true
    canvasView.bottomAnchor.constraint(equalTo: preview.bottomAnchor).isActive = true
    canvasView.rightAnchor.constraint(equalTo: preview.rightAnchor).isActive = true

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
    if(displayedStyle != nil && ProcessInfo.processInfo.isLowPowerModeEnabled){return}
    
    visible = self.isVisible()
    if(!visible){return}
    
    let newUserInterfaceStyle: UIUserInterfaceStyle = _layer!.needsDarkUI ? .dark : .light
    
    if(canvasView.overrideUserInterfaceStyle != newUserInterfaceStyle){
      canvasView.overrideUserInterfaceStyle = newUserInterfaceStyle
      canvasView.setNeedsDisplay()
    }
   
    if(queuedStyle != displayedStyle) {
      displayedStyle = queuedStyle
      preview.styleURL = displayedStyle!.url
      preview.tintColor = _layer!.style.colour ?? (_layer!.needsDarkUI ? .white : .systemBlue)
      
      styleCachedConstraints = (displayedStyle!.zoomLevelsCovered, displayedStyle!.bounds)
    }
    
    let zoomLevel = MapViewController.shared.mapView.zoomLevel
    let visibleBounds = MapViewController.shared.mapView.visibleCoordinateBounds
    
    if(zoomLevel < styleCachedConstraints!.zoomLevelsCovered.0 - 2){
      previewBlurReasons.append(.minZoom)

      return
    } else if(!previewBlurReasons.isEmpty) {
      previewBlurReasons = previewBlurReasons.filter({$0 != .minZoom})
    }
    
    if(styleCachedConstraints!.bounds.superbound != nil && !visibleBounds.intersects(with: styleCachedConstraints!.bounds.superbound!)){
      previewBlurReasons.append(.bounds)
      
      return
    } else if(!previewBlurReasons.isEmpty) {
      previewBlurReasons = previewBlurReasons.filter({$0 != .bounds})
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

  func update(_layer: Layer, layerSelectConfig: LayerSelectConfig, scrollView: LayerSelectView, accessory: LayerCellAccessory) {
    self._layer = _layer
    self.accessory = accessory
 
    queuedStyle = _layer.style
    
    height.constant = _layer.enabled ? 95 : 70
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
    
    preview.tintColor = _layer.style.colour ?? (_layer.needsDarkUI ? .white : .systemBlue)

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

enum PreviewBlurReason {
  case minZoom
  case bounds
}

enum LayerCellAccessory: Equatable {
  case plus(Int)
  case collapse
  case normal
}
