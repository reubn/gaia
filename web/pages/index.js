import {useState, useEffect} from 'react'

import layerManager from '@/managers/layerManager'

import Map from '@/components/Map'
import LayerSelect from '@/components/LayerSelect'
import MaxTileZoomSelect from '@/components/MaxTileZoomSelect'
import ExaggerationSelect from '@/components/ExaggerationSelect'

import KeyCombo from '@/components/KeyCombo'

export default () => {
  const lm = typeof window !== 'undefined' ? layerManager.useLayerManager() : []
  const [maxTileZoom, setMaxTileZoom] = useState(17)
  global.setMaxTileZoom = setMaxTileZoom
  const [exaggeration, setExaggeration] = useState(0)
  global.setExaggeration = setExaggeration

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
        terrain: exaggeration ? {
          ...style.terrain,
          exaggeration: exaggeration
        } : style.terrain
      }
    })

  }, [lm, maxTileZoom, exaggeration])

  return (
    <section>
      <Map {...state} darkMode={darkMode}  />
      <LayerSelect darkMode={darkMode} />
      <MaxTileZoomSelect value={maxTileZoom} onChange={e => setMaxTileZoom(e.target.value)} />
      <ExaggerationSelect value={exaggeration} onChange={e => setExaggeration(+e.target.value)} />

      <KeyCombo combo="ctrl+=" handler={() => setMaxTileZoom(maxTileZoom + 1)} />
      <KeyCombo combo="ctrl+-" handler={() => setMaxTileZoom(maxTileZoom - 1)} />
    </section>
  )
}
