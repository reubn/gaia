import {useState, useEffect, useRef} from 'react'
import SuperMap from './SuperMap'
import KeyCombo from '@/components/KeyCombo'

import {map as mapStyle, light, dark} from './styles'

const Map = ({lat, lng, zoom, bearing, pitch, style, darkMode}) => {
  const mapContainer = useRef()
  const [map, setMap] = useState(null)

  useEffect(() => {
    const map = new SuperMap({
      container: mapContainer.current,
      style,
      center: [lng, lat],
      zoom,
      bearing: bearing || 0,
      pitch: pitch || 0,

      attributionControl: false,
      renderWorldCopies: false,

      workerCount: 4,
      maxParallelImageRequests: 32,
      diff: true
    })

    setMap(map)

    return () => {map.remove(); delete global.map}
  }, [mapContainer])

  useEffect(() => {
    map && map.setCenter({lat, lng})
  }, [map, lat, lng])

  useEffect(() => {
    map && map.setZoom(zoom)
  }, [map, zoom])

  useEffect(() => {
    map && map.setStyle(style)
  }, [map, style])

  return (
    <>
      <div className={`${mapStyle} ${darkMode ? dark : light}`} ref={mapContainer} />
      <KeyCombo combo="`" handler={() => map.resetNorthPitch()} />
      <KeyCombo combo="ctrl+g" handler={() => map.streetViewMode = true} />
    </>

  )
}


export default Map
