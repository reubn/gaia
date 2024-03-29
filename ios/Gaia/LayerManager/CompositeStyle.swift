import Foundation

struct CompositeStyle: Equatable, Hashable {
  let sortedLayers: [Layer]
  
  var topOpaque: Layer? {
    sortedLayers.first(where: {$0.isOpaque})
  }
  
  var needsDarkUI: Bool {
    topOpaque?.needsDarkUI ?? sortedLayers.first?.needsDarkUI ?? true
  }
  
  var isEmpty: Bool {
    sortedLayers.isEmpty
  }
  
  var hasMultipleOpaque: Bool {
    sortedLayers.filter({$0.isOpaque}).count > 1
  }
  
  var revealedLayers: [Layer] {
    sortedLayers.filter({!$0.isOpaque || $0 == topOpaque})
  }
  
  func toStyle() -> Style {
    var sources: [String: Style.Source] = [:]
    var layers: [Style.Layer] = []
    
    var sprite: Style.Sprite? = nil
    var glyphs: Style.Glyphs? = nil
    var terrain: Style.Terrain? = nil
    
    for layer in sortedLayers.reversed() {
      let style = layer.style
      
      sources.merge(style.sources) {(_, new) in new}
      layers += style.layers
      
      sprite = sprite ?? style.sprite
      glyphs = glyphs ?? style.glyphs
      terrain = terrain ?? style.terrain
    }

    return Style(
      sources: sources,
      layers: layers,
      
      sprite: sprite,
      glyphs: glyphs,
      terrain: terrain
    )
  }
  
  init(sortedLayers: [Layer]){
    self.sortedLayers = sortedLayers
  }
}
