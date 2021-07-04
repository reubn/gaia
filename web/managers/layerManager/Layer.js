export default class Layer {
  id = ''
  name = ''
  group = ''
  groupIndex = ''
  attribution = ''
  overrideUIMode = ''

  visible = false
  enabled = false
  pinned = false


  style = undefined

  constructor({id = '', name = '', group = '', groupIndex = 0, visible = false, enabled = false, pinned = false, attribution = '', overrideUIMode = '', style = undefined}){
    this.id = id
    this.name = name
    this.group = group
    this.groupIndex = groupIndex
    this.attribution = attribution
    this.overrideUIMode = overrideUIMode

    this.visible = visible
    this.enabled = enabled
    this.pinned = pinned


    this.style = style
  }

  static fromLayerDefinition({metadata, user, style}){
    const layer = {}
    layer.id = metadata.id
    layer.name = metadata.name
    layer.group = metadata.group
    layer.overrideUIMode = metadata.overrideUIMode
    layer.attribution = metadata.attribution

    if(user){
      layer.groupIndex = user.groupIndex

      layer.pinned = user.pinned
      layer.enabled = user.enabled
    }

    layer.style = style

    return new Layer(layer)
  }

  get needsDarkUI(){
    if(this.overrideUIMode == "dark") return true
    if(this.overrideUIMode == "light") return false

    return this.group == "aerial" || this.group == "overlay"
  }

  get isOpaque(){
    return this.group != "gpx" && this.group != "overlay"
  }

  get layerDefinition(){
    return {
      metadata: {
        id: this.id,
        name: this.name,
        group: this.group
      },
      user: {
        groupIndex: this.groupIndex,
        pinned: this.pinned,
        enabled: this.enabled
      },
      style: this.style
    }
  }
}
