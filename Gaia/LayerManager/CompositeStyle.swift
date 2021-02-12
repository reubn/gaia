import Foundation

class CompositeStyle {
  let sortedLayers: [Layer]
  
  var needsDarkUI: Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    if(topNonOverlay == nil) {return true}

    return topNonOverlay!.group == "aerial"
  }
  
  var url: URL? {
    CompositeStyle.toURL(style: style)
  }
  
  var style: Style {
    var sources: [String: Style.Source] = [:]
    var layers: [Style.Layer] = []
    
    for layer in sortedLayers {
      let style = layer.style
      
      sources.merge(style.sources) {(_, new) in new}
      layers += style.layers
    }

    return Style(
      sources: sources,
      layers: layers
    )
  }
  
  init(sortedLayers: [Layer]){
    self.sortedLayers = sortedLayers
  }
  
  static func toURL(data: Data) -> URL? {
    do {
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFilename = ProcessInfo().globallyUniqueString
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try data.write(to: temporaryFileURL, options: .atomic)
      
      return temporaryFileURL
    }
    catch {
      return nil
    }
  }
  
  static func toURL(style: Style) -> URL? {
    do {
      let encoder = JSONEncoder()

      return CompositeStyle.toURL(data: try encoder.encode(style))
      
    } catch {
      return nil
    }
  }
}
