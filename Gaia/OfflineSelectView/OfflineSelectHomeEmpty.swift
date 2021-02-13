import Foundation
import UIKit

class OfflineSelectHomeEmpty: UIView {
  let offlineManager: OfflineManager
  
  lazy var title: UILabel = {
    let label = UILabel()
      
    label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    return label
  }()
  
  lazy var subtitle: UILabel = {
    let label = UILabel()
      
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    label.textColor = .tertiaryLabel
    label.numberOfLines = 0

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: title.bottomAnchor).isActive = true
    label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    return label
  }()
  
  init(offlineManager: OfflineManager){
    self.offlineManager = offlineManager
    
    super.init(frame: CGRect())
  }
  
  func update(){
    if(offlineManager.downloads?.count ?? 0 == 0){
      title.text = "Saved Regions"
      subtitle.text = "Download areas to use when offline"
      isHidden = false
    } else {isHidden = true}
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
