export default class CompositeStyle {
  sortedLayers = []

  constructor(sortedLayers){
    this.sortedLayers = sortedLayers
  }

  get topOpaque(){
    return this.sortedLayers.find(layer => layer.isOpaque)
  }

  get needsDarkUI(){
    return this.topOpaque.needsDarkUI
  }


  toStyle() {
    let sources = {}
    let layers = []

    let sprite = undefined
    let glyphs = undefined
    let terrain = undefined

    for(let layer of this.sortedLayers) {
      const style = layer.style

      sources = {...sources, ...style.sources}
      layers = [...layers, ...style.layers]

      sprite = sprite || style.sprite
      glyphs = glyphs || style.glyphs
      terrain = terrain || style.terrain
    }

    const style = {
      version: 8,
      sources: sources,
      layers: layers,

      sprite: sprite,
      glyphs: glyphs,
      terrain: terrain
    }

    Object.keys(style).forEach(key => style[key] === undefined && delete style[key])

    return style
  }
}
