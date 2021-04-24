import {useState, useEffect, useRef} from 'react'
import SuperMap from './SuperMap'

import {map as mapStyle} from './styles'

const Map = ({lat, lng, zoom, style}) => {
  const mapContainer = useRef()
  const [map, setMap] = useState(null)

  useEffect(() => {
    const map = new SuperMap({
      container: mapContainer.current,
      style: style,
      center: [lng, lat],
      zoom: zoom,

      attributionControl: false,
      renderWorldCopies: false
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
    <div className={mapStyle} ref={mapContainer} />
  )
}


export default Map
