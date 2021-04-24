import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import Map from '@/components/Map'
import LayerCell from './LayerCell'

import {layerSelect} from './styles'

const LayerSelect = () => {
  if(typeof window === 'undefined') return null
  const layers = layerManager.useLayers()

  const onClick = layer => {
    if(layer.visible) layerManager.hide(layer, true)
    else layerManager.show(layer, true)
  }

  const layerCells = layers.sort(layerManager.layerSortingFunction).reverse().map(layer => <LayerCell layer={layer} onClick={onClick} />)

  return <section className={layerSelect}>{layerCells}</section>
}

export default () => {
  const lmls = typeof window !== 'undefined' ? layerManager.useLayers() : []

  const [state, setState] = useState({
    lat: 52.7577,
    lng: -2.4376,
    zoom: 8
  }, [])


  useEffect(() => {
    const {s: sources, l: layers} = lmls
    .filter(({visible}) => visible)
    .sort(layerManager.layerSortingFunction)
    .reduce(({s, l}, {metadata, style: {layers, sources}}) => ({
      l: [...l, ...layers],
      s: {...s, ...sources}
    }), {s: {}, l: []})

    console.log(layers)
    setState({
      ...state,
      style: {
        version: 8,
        sources: {
          ...sources,
          'mapbox-dem': {
            'type': 'raster-dem',
            'url': 'mapbox://mapbox.mapbox-terrain-dem-v1',
            'tileSize': 512,
            'maxzoom': 14
          }
        },
        layers,
        terrain: {
          source: 'mapbox-dem',
          exaggeration: 2
        }
      }
    })
  }, [lmls])

  return (
    <section>
      <Map {...state} />
      <LayerSelect />
    </section>
  )
}
