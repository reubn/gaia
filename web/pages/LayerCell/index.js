import {layerCell, visible} from './styles'

export default ({layer, onClick}) => {

  return (
    <div className={layerCell} onClick={() => onClick(layer)}>
      <p className={layer.visible ? visible : ''}>{layer.name}</p>
    </div>
  )
}
