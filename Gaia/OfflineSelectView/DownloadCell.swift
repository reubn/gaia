import Foundation
import UIKit
import CoreData

import Mapbox

class DownloadCell: UITableViewCell {
  let _t = 16
  
  let cellHeight: CGFloat = 100
  let previewSpacing: CGFloat = 15
  lazy var previewSize: CGFloat = cellHeight - (2 * previewSpacing)
  
  var pack: MGLOfflinePack?
  var context: PackContext? = nil
  var first = true
  
  var layersString = ""
  
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
    stack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: previewSpacing + previewSize + previewSpacing).isActive = true
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
    preview.layer.cornerRadius = 5
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
    preview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    preview.centerXAnchor.constraint(equalTo: contentView.leftAnchor, constant: previewSpacing + (previewSize / 2)).isActive = true
    
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
    
    let height = contentView.heightAnchor.constraint(equalToConstant: cellHeight)
    height.priority = UILayoutPriority(rawValue: 999)
    height.isActive = true

    backgroundColor = .clear
  }
  

  func update(pack: MGLOfflinePack) {
    self.pack = pack
    
    context = OfflineManager.shared.decodePackContext(pack: pack)
    
    if(context == nil) {return}

    let byteString = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: .memory)
    
    title.text = context!.name
    subtitle.text = String(format: "%@ - %@ @ %d-%d", byteString, layersString, context!.fromZoomLevel!, context!.toZoomLevel!)
    
    status = pack.state
    
    if(first) {
      first = false
      
      let layersMetadata = context!.layerMetadata
      let orderedLayersMetadata = layersMetadata.sorted(by: LayerManager.shared.layerSortingFunction).reversed()
      layersString = orderedLayersMetadata.map({$0.name}).joined(separator: ", ")
      
      let bounds = MGLCoordinateBounds(context!.bounds)
      let coordinateSpan = MGLCoordinateBoundsGetCoordinateSpan(bounds)
      
      let height = coordinateSpan.latitudeDelta
      let width = coordinateSpan.longitudeDelta
      
      if(height >= width){
        preview.heightAnchor.constraint(equalToConstant: previewSize).isActive = true
        preview.widthAnchor.constraint(equalTo: preview.heightAnchor, multiplier: CGFloat(width / height)).isActive = true
      } else {
        preview.widthAnchor.constraint(equalToConstant: previewSize).isActive = true
        preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: CGFloat(height / width)).isActive = true
      }
      
      preview.styleURL = context!.style.url
      preview.setVisibleCoordinateBounds(bounds, animated: false)
    }
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}
