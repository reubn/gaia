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
      <KeyCombo combo="s" handler={toggleLayer('stravaRun')} />
      <KeyCombo combo="o" handler={toggleLayer('magicOS', 'bingSat')} />
    </section>
  )
}

const toggleLayer = (id, id2) => () => {
    const layer = layerManager.layers.find(({id: _id}) => id == _id)
    const layer2 = id2 && layerManager.layers.find(({id: _id}) => id2 == _id)

    if(layer.visible) {
      if(id2) layerManager.show(layer2)
      layerManager.hide(layer)
    }
    else {
      layerManager.show(layer)
      if(id2) layerManager.hide(layer2)
    }
  }
