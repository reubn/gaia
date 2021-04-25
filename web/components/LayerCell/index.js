import {layerCell, visible, preview, name, accessory} from './styles'

export default ({layer, onClick}) => {

  return (
    <div className={`${layerCell} ${layer.visible ? visible : ''}`} onClick={() => onClick(layer)}>
    <div className={preview} />
    <p className={name}>{layer.name}</p>
    <p className={accessory}>{layer.visible ? '􀆅' : ''}</p>
    </div>
  )
}
