import Foundation

class Style {
  let sortedLayers: [Layer]
  
  var needsDarkUI: Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    if(topNonOverlay == nil) {return true}

    return topNonOverlay!.group == "aerial"
  }
  
  var url: URL? {
    Style.toURL(styleJSON: styleJSON)
  }
  
  var styleJSON: StyleJSON {
    var sources: [String: StyleJSON.Source] = [:]
    var layers: [StyleJSON.Layer] = []
    
    for layer in sortedLayers {
      let styleJSON = layer.styleJSON
      
      sources.merge(styleJSON.sources) {(_, new) in new}
      layers += styleJSON.layers
    }

    return StyleJSON(
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
  
  static func toURL(styleJSON: StyleJSON) -> URL? {
    do {
      let encoder = JSONEncoder()

      return Style.toURL(data: try encoder.encode(styleJSON))
      
    } catch {
      return nil
    }
  }
}
