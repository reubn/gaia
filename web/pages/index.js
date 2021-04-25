import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import Map from '@/components/Map'
import LayerCell from './LayerCell'

import {layerSelect, light, dark} from './styles'

const LayerSelect = ({darkMode=false}) => {
  if(typeof window === 'undefined') return null
  layerManager.useLayerManager()

  const layers = layerManager.layers

  const onClick = layer => {
    if(layer.visible) layerManager.hide(layer, true)
    else layerManager.show(layer, true)
  }

  const layerCells = layers.sort(layerManager.layerSortingFunction).reverse().map(layer => <LayerCell layer={layer} onClick={onClick} />)

  return <section className={`${layerSelect} ${darkMode ? dark : light}`}>{layerCells}</section>
}

export default () => {
  const lm = typeof window !== 'undefined' ? layerManager.useLayerManager() : []

  const [state, setState] = useState({
    lat: 52.7577,
    lng: -2.4376,
    zoom: 8
  })

  const [darkMode, setDarkMode] = useState(false)

  useEffect(() => {
    const compositeStyle = layerManager.compositeStyle
    let style = compositeStyle.toStyle()

    console.log(compositeStyle.needsDarkUI)
    setDarkMode(compositeStyle.needsDarkUI)
    setState({
      ...state,
      style: {
        ...style,
        sources: {
          ...style.sources,
          'mapbox-dem': {
            'type': 'raster-dem',
            'url': 'mapbox://mapbox.mapbox-terrain-dem-v1',
            'tileSize': 512,
            'maxzoom': 14
          }
        },
        terrain: {
          source: 'mapbox-dem',
          exaggeration: 2
        }
      }
    })
  }, [lm])

  return (
    <section>
      <Map {...state} darkMode={darkMode}  />
      <LayerSelect darkMode={darkMode} />
    </section>
  )
}
