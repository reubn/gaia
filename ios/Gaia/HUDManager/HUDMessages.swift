extension HUDMessage {
  static let syntaxError = HUDMessage(title: "Syntax Error", systemName: "xmark.octagon.fill", tintColour: .systemRed)
  static let urlInvalid = HUDMessage(title: "URL Invalid", systemName: "link", tintColour: .systemRed)
  static func layerDeleted(_ layerName: String) -> HUDMessage {
    HUDMessage(title: layerName + " Deleted", systemName: "trash.fill", tintColour: .systemRed)
  }
  
  static let layerNotModified = HUDMessage(title: "Layer Not Modified", systemName: "slash.circle.fill", tintColour: .systemYellow)
  
  static let layerCreated = HUDMessage(title: "Layer Created", systemName: "plus.square.fill", tintColour: .systemBlue)
  static let layerSaved = HUDMessage(title: "Layer Saved", systemName: "checkmark.square.fill", tintColour: .systemBlue)
  static func layersAccepted(_ results: LayerAcceptanceResults, importing: Bool = false) -> HUDMessage {
    let added: String
    if(results.added.isEmpty){
      added = ""
    } else if(results.added.count == 1){
      added = "1 Layer Added"
    } else {
      added = "\(results.added.count) Layers Added"
    }
    
    let updated: String
    if(results.updated.isEmpty){
      updated = ""
    } else if(results.updated.count == 1){
      updated = "1 Layer Updated"
    } else {
      updated = "\(results.updated.count) Layers Updated"
    }
    
    let title: String
    let systemName: String
    switch (added, updated) {
      case (_, ""):
        title = added
        systemName = importing
          ? (results.updated.count == 1 ? "square.and.arrow.down.fill" : "square.and.arrow.down.on.square.fill")
          : (results.added.count == 1 ? "plus.square.fill" : "plus.square.fill.on.square.fill")
      case ("", _):
        title = updated
        systemName = importing
          ? (results.updated.count == 1 ? "square.and.arrow.down.fill" : "square.and.arrow.down.on.square.fill")
          : (results.updated.count == 1 ? "checkmark.square.fill" : "square.fill.on.square")
      case (_, _):
        title = "\(added), \(updated)"
        systemName = importing ? "square.and.arrow.down.on.square.fill" : "plus.square.fill.on.square.fill"
    }
    
    return HUDMessage(title: title, systemName: systemName, tintColour: .systemBlue)
  }
  static func layerRejected(_ results: LayerAcceptanceResults, importing: Bool = false) -> HUDMessage {
    let error = results.rejected.first!.error!
    
    let title: String
    
    switch error {
      case .layerExistsWithId(let id):
        title = "Layer `\(id)` Already Exists"
      case .noLayerExistsWithId(let id):
        title = "Layer `\(id)` Does Not Exists"
      case .unexplained:
        title = importing ? "Couldn't Import Layer" : "Couldn't Add Layer"
    }
    
    return HUDMessage(title: title, systemName: "xmark.octagon.fill", tintColour: .systemRed)
  }
  
  static func quickToggle(_ tuple: (count: Int, restore: Bool)) -> HUDMessage {
    let (count, restore) = tuple
    
    let quantity = count == 1
      ? "Layer"
      : "\(count) Layers"
    
    return HUDMessage.Quick(
      title: "\(quantity) \(restore ? "Restored" : "Hidden")",
      systemName: "bolt.fill",
      tintColour: .systemYellow
    )
  }
  
  static func magicPinned(_ layer: Layer) -> HUDMessage {
    return HUDMessage.Quick(title: layer.name, systemName: "pin.fill", tintColour: .systemBlue)
  }
  
  static let urlCommandInvalid = HUDMessage(title: "Command Invalid", systemName: "xmark.octagon.fill", tintColour: .systemRed)
  
  static let noLayersWarningFixed = HUDMessage(title: "Layers Restored", systemName: "square.stack.3d.up.fill", tintColour: .systemGreen)
  static let zoomWarningFixed = HUDMessage(title: "Zoom Fixed", systemName: "arrow.up.left.and.down.right.magnifyingglass", tintColour: .systemGreen)
  static let multipleOpaqueWarningFixed = HUDMessage(title: "Layers Removed", systemName: "square.3.stack.3d.top.fill", tintColour: .systemGreen)
  static let boundsWarningFixed = HUDMessage(title: "Bounds Fixed", systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", tintColour: .systemGreen)
  static let zeroOpacityWarningFixed = HUDMessage(title: "Opacity Fixed", systemName: "slider.horizontal.below.rectangle", tintColour: .systemGreen)
  
  static let cacheCleared = HUDMessage(title: "Cache Cleared", systemName: "trash", tintColour: .systemRed)
  
  static let offlineModeEnabled = HUDMessage(title: "Offline Mode Enabled", systemName: "icloud.slash.fill", tintColour: .systemBlue)
  static let offlineModeDisabled = HUDMessage(title: "Offline Mode Disabled", systemName: "icloud.fill", tintColour: .systemBlue)
  static let warnDownloadInOfflineMode = HUDMessage(title: "Can't Download in Offline Mode", systemName: "icloud.slash.fill", tintColour: .systemRed)
  
  static let autoAdjustmentEnabled = HUDMessage(title: "Auto Adjustment Enabled", systemName: "sun.max.fill", tintColour: .systemBlue)
  static let autoAdjustmentDisabled = HUDMessage(title: "Auto Adjustment Disabled", systemName: "sun.min.fill", tintColour: .systemBlue)
  static let autoAdjustmentSetLow = HUDMessage(title: "Low Brightness Set", systemName: "sun.min.fill", tintColour: .systemBlue)
}
