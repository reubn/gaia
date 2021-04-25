import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import LayerCell from '@/components/LayerCell'

import {layerSelect, light, dark, open as openStyle, closed as closedStyle, handle, locked as lockedStyle} from './styles'

const LayerSelect = ({darkMode=false}) => {
  if(typeof window === 'undefined') return null
  layerManager.useLayerManager()

  const layers = layerManager.layers

  const [open, setOpen] = useState(false)
  const [locked, setLocked] = useState(false)
  const [hover, setHover] = useState(false)

  useEffect(() => {
    if(!locked && hover) setOpen(true)
    else if(locked && !hover) setOpen(true)
    else if(!locked && !hover) setOpen(false)
    else if(locked && hover) setOpen(true)
  }, [locked, hover])

  const onClick = layer => {
    if(layer.visible) layerManager.hide(layer, true)
    else layerManager.show(layer, true)

    setLocked(true)
  }

  const content = open
    ? layers.sort(layerManager.layerSortingFunction).reverse().map(layer => <LayerCell layer={layer} onClick={onClick} />)
    : []

  return (
    <section className={`${layerSelect} ${darkMode ? dark : light} ${open ? openStyle : closedStyle}`} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      <p className={`${handle} ${locked ? lockedStyle : ''}`} onClick={() => setLocked(!locked)}>􀆈</p>
      {content}
    </section>
  )
}

export default LayerSelect
