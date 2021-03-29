import Foundation

struct CompositeStyle: Equatable, Hashable {
  static func == (lhs: CompositeStyle, rhs: CompositeStyle) -> Bool {
    lhs.sortedLayers == rhs.sortedLayers
  }
  
  let sortedLayers: [Layer]
  
  var topOpaque: Layer? {
    sortedLayers.first(where: {$0.isOpaque})
  }
  
  var needsDarkUI: Bool {
    topOpaque?.needsDarkUI ?? true
  }
  
  var isEmpty: Bool {
    sortedLayers.isEmpty
  }
  
  var hasMultipleOpaque: Bool {
    sortedLayers.filter({$0.isOpaque}).count > 1
  }
  
  var url: URL? {
    style.url
  }
  
  var revealedLayers: [Layer] {
    sortedLayers.filter({!$0.isOpaque || $0 == topOpaque})
  }
  
  var style: Style {
    var sources: [String: Style.Source] = [:]
    var layers: [Style.Layer] = []
    
    for layer in sortedLayers.reversed() {
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
