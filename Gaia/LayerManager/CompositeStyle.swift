import Foundation

class CompositeStyle {
  let sortedLayers: [Layer]
  
  var needsDarkUI: Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    return topNonOverlay?.needsDarkUI ?? true
  }
  
  var isEmpty: Bool {
    sortedLayers.isEmpty
  }
  
  var hasMultipleOpaque: Bool {
    sortedLayers.filter({$0.group != "overlay"}).count > 1
  }
  
  var url: URL? {
    style.url
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
}
