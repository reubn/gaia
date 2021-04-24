export default class Layer {
  id = ''
  name = ''
  group = ''
  groupIndex = ''

  visible = false
  enabled = false
  pinned = false


  style = undefined

  constructor({id = '', name = '', group = '', groupIndex = 0, visible = false, enabled = false, pinned = false, style = undefined}){
    this.id = id
    this.name = name
    this.group = group
    this.groupIndex = groupIndex

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

    if(user){
      layer.groupIndex = user.groupIndex

      layer.pinned = user.pinned
      layer.enabled = user.enabled
    }

    layer.style = style

    return new Layer(layer)
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
