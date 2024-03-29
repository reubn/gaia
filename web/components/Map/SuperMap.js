import mapboxgl from 'mapbox-gl/dist/mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

import {accessToken} from './secret'

import initDraw from './draw'

mapboxgl.accessToken = accessToken

class SuperMap extends mapboxgl.Map {
  constructor(options){
    super({
      ...options,
      attributionControl: false,
      renderWorldCopies: false,
      maxTileCacheSize: Infinity
    })

    global.map = this

    initDraw(map)

    map.on('moveend', () => {
      const state = {
        zoom: map.getZoom(),
        bearing: map.getBearing(),
        pitch: map.getPitch(),
        ...map.getCenter()
      }

      localStorage.setItem('state', JSON.stringify(state))
    })

    map.on('click', ({lngLat: {lat, lng}}) => {
      if(map.streetViewMode) window.open(`http://maps.google.com/maps?q=&layer=c&cbll=${lat},${lng}&cbp=11,0,0,0,0`)
      map.streetViewMode = false
    })
  }
}

export default SuperMap
