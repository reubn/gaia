extension HUDMessage {
  static let syntaxError = HUDMessage(title: "Syntax Error", systemName: "xmark.octagon.fill", tintColour: .systemRed)
  static let importError = HUDMessage(title: "Import Error", systemName: "xmark.octagon.fill", tintColour: .systemRed)
  static func layerDeleted(_ layerName: String) -> HUDMessage {
    HUDMessage(title: layerName + " Deleted", systemName: "trash.fill", tintColour: .systemRed)
  }
  
  static let layerCreated = HUDMessage(title: "Layer Created", systemName: "plus.square.fill", tintColour: .systemBlue)
  static let layerSaved = HUDMessage(title: "Layer Saved", systemName: "checkmark.square.fill", tintColour: .systemBlue)
  static func layersImported(_ count: Int) -> HUDMessage {
    let (title, systemName) = count == 1
      ? (title: "Layer Imported", systemName: "square.and.arrow.down.fill")
      : (title: "\(count) Layers Imported", systemName: "square.and.arrow.down.on.square.fill")
    
    return HUDMessage(title: title, systemName: systemName, tintColour: .systemBlue)
  }
  
  static func magic(_ tuple: (count: Int, restore: Bool)) -> HUDMessage {
    let (count, restore) = tuple
    
    let quantity = count == 1
      ? "1 Layer"
      : "\(count) Layers"
    
    return HUDMessage(
      title: "\(quantity) \(restore ? "Restored" : "Hidden")",
      systemName: "sparkles",
      tintColour: restore ? .systemYellow : nil,
      duration: 1
    )
  }
}
