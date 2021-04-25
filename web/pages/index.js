import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import Map from '@/components/Map'
import LayerSelect from '@/components/LayerSelect'

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
