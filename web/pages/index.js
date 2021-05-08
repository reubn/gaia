import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import Map from '@/components/Map'
import LayerSelect from '@/components/LayerSelect'
import MaxTileZoomSelect from '@/components/MaxTileZoomSelect'

import KeyCombo from '@/components/KeyCombo'

export default () => {
  const lm = typeof window !== 'undefined' ? layerManager.useLayerManager() : []
  const [maxTileZoom, setMaxTileZoom] = useState(17)
  global.setMaxTileZoom = setMaxTileZoom

  const [state, setState] = useState({
    lat: 52.7577,
    lng: -2.4376,
    zoom: 8
  })

  const [darkMode, setDarkMode] = useState(false)

  useEffect(() => {
    const compositeStyle = layerManager.compositeStyle
    let style = compositeStyle.toStyle({maxTileZoom})

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
  }, [lm, maxTileZoom])

  return (
    <section>
      <Map {...state} darkMode={darkMode}  />
      <LayerSelect darkMode={darkMode} />
      <MaxTileZoomSelect value={maxTileZoom} onChange={e => setMaxTileZoom(e.target.value)} />

      <KeyCombo combo="ctrl+=" handler={() => setMaxTileZoom(maxTileZoom + 1)} />
      <KeyCombo combo="ctrl+-" handler={() => setMaxTileZoom(maxTileZoom - 1)} />
    </section>
  )
}
