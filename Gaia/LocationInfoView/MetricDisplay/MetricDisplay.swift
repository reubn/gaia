import Foundation
import UIKit

class MetricDisplay: UIView {
  var value: Any? {
    didSet {updateValue()}
  }
  var emoji: String? {
    didSet {updateEmoji()}
  }
  
  lazy var emojiLabel: UILabel = {
    let label = UILabel()
    label.text = emoji
    
    label.font = UIFont.systemFont(ofSize: 20)
    label.textColor = .secondaryLabel
    
    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    label.topAnchor.constraint(equalTo: topAnchor).isActive = true
    
    return label
  }()
  
  lazy var valueLabel: SelectableLabel = {
    let label = SelectableLabel()
    let tuple = format()
    
    label.text = tuple.0
    label.textToSelect = tuple.1
    label.isSelectable = true
    
    label.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .medium)
    label.textColor = .secondaryLabel
    
    addSubview(label)
    
    label.translatesAutoresizingMaskIntoConstraints = false
    label.leftAnchor.constraint(equalTo: emojiLabel.rightAnchor, constant: 5).isActive = true
    label.centerYAnchor.constraint(equalTo: emojiLabel.centerYAnchor).isActive = true
    
    return label
  }()
  
  init(){
    super.init(frame: CGRect())
    isUserInteractionEnabled = true
    
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
    addGestureRecognizer(tapRecognizer)
    
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 100).isActive = true
    heightAnchor.constraint(equalToConstant: 20).isActive = true
    
    updateValue()
  }
  
  func updateValue(){
    let tuple = format()
    
    valueLabel.text = tuple.0
    valueLabel.textToSelect = tuple.1
  }
  
  func updateEmoji(){
    emojiLabel.text = emoji
  }
  
  @objc func tapped(){}
  
  func format() -> (String, String) {
    let string = String(describing: value)
    
    return (string, string)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
