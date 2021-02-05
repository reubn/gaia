import Foundation
import UIKit
import CoreData

import Mapbox

class DownloadCell: UITableViewCell {
  let _t = 16
  
  let previewSpacing: CGFloat = 15
  
  var pack: MGLOfflinePack?
  var mapViewController: MapViewController?
  var context: PackContext? = nil
  
  var _status: MGLOfflinePackState?
  var status: MGLOfflinePackState? {
    get {_status}
    set {
      
      if(newValue == _status) {return}
      _status = newValue
      
      switch newValue {
        case .unknown:
          statusIcon.setImage(nil, for: .normal)
          statusIcon.layer.removeAnimation(forKey: "rotationAnimation")
        case .inactive:
          statusIcon.setImage(UIImage(systemName: "exclamationmark.triangle.fill"), for: .normal)
          statusIcon.tintColor = .systemYellow
          statusIcon.layer.removeAnimation(forKey: "rotationAnimation")
        case .active:
          statusIcon.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill"), for: .normal)
          statusIcon.tintColor = .systemBlue
          statusIcon.layer.add(rotationAnimation, forKey: "rotationAnimation")
        case .complete:
          statusIcon.setImage(nil, for: .normal)
          statusIcon.layer.removeAnimation(forKey: "rotationAnimation")
        case .invalid:
          statusIcon.setImage(UIImage(systemName: "xmark.octagon.fill"), for: .normal)
          statusIcon.tintColor = .systemRed
          statusIcon.layer.removeAnimation(forKey: "rotationAnimation")

        default:
          statusIcon.setImage(UIImage(systemName: "xmark.octagon.fill"), for: .normal)
          statusIcon.tintColor = .systemRed
          statusIcon.layer.removeAnimation(forKey: "rotationAnimation")
      }
    }
  }
  
  lazy var stack: UIStackView = {
    let stack = UIStackView()
    
    stack.axis = .vertical
    stack.alignment = .leading
    stack.distribution = .equalCentering
    stack.spacing = 0
    
    contentView.addSubview(stack)
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.leftAnchor.constraint(equalTo: preview.rightAnchor, constant: previewSpacing).isActive = true
    stack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -previewSpacing).isActive = true
    stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    
    return stack
  }()
  
  lazy var title: UILabel = {
    let label = UILabel()
    
    label.font = UIFont.systemFont(ofSize: 18)
    label.textColor = UIColor.label
    
    stack.addArrangedSubview(label)

    return label
  }()
  
  lazy var subtitle: UILabel = {
    let label = UILabel()
    
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.clipsToBounds = true
    
    stack.addArrangedSubview(label)

    return label
  }()
  
  lazy var preview: MGLMapView = {
    let preview = MGLMapView()
    preview.layer.cornerRadius = 10
    preview.layer.cornerCurve = .continuous
    preview.clipsToBounds = true
    preview.backgroundColor = .black
    preview.layer.allowsEdgeAntialiasing = true
    preview.isUserInteractionEnabled = false
    
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
    
    return preview
  }()
  
  lazy var statusIcon: UIButton = {
    let button = UIButton()
    button.contentVerticalAlignment = .fill
    button.contentHorizontalAlignment = .fill
    button.imageView!.contentMode = .scaleAspectFit

    contentView.addSubview(button)

    button.translatesAutoresizingMaskIntoConstraints = false
    button.widthAnchor.constraint(equalToConstant: 25).isActive = true
    button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
    button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: previewSpacing).isActive = true
    button.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -previewSpacing).isActive = true

    return button
  }()
  
  lazy var rotationAnimation: CAAnimation = {
    let animation = CABasicAnimation.init(keyPath: "transform.rotation.z")
    animation.toValue = NSNumber(value: Double.pi)
    animation.duration = 1.0
    animation.isCumulative = true
    animation.repeatCount = .greatestFiniteMagnitude
    
    return animation
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    autoresizingMask = .flexibleHeight
    
    let height = contentView.heightAnchor.constraint(equalToConstant: 100)
    height.priority = UILayoutPriority(rawValue: 999)
    height.isActive = true

    backgroundColor = .clear
  }
  

  func update(pack: MGLOfflinePack, mapViewController: MapViewController) {
    self.pack = pack
    self.mapViewController = mapViewController
    
    var layersString = ""
    var zoomString = ""
    if(context != nil) {
      let layers = context!.layerMetadata
      
      layersString = " - "
      
      for (index, layer) in layers.enumerated() {
        if(index > 0) {layersString += ", "}
        layersString += "\(layer.name)"
      }
      
      if(context!.fromZoomLevel != nil) {
        zoomString = String(format: " @ %d-%d", context!.fromZoomLevel!, context!.toZoomLevel!)
      }
      
    }
    
    subtitle.text = "\(ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory))\(layersString)\(zoomString)"
    status = pack.state
    
    context = mapViewController.offlineManager.decodePackContext(pack: pack)
    
    if(context == nil) {return}
    
    title.text = context!.name
    
    preview.styleURL = Style.toURL(styleJSON: context!.styleJSON)
    preview.setVisibleCoordinateBounds(MGLCoordinateBounds(context!.bounds), animated: false)
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}
