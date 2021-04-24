import mapboxgl from 'mapbox-gl/dist/mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

import {accessToken} from './secret'

mapboxgl.accessToken = accessToken

class SuperMap extends mapboxgl.Map {
  constructor(options){
    super({
      ...options,
      attributionControl: false,
      renderWorldCopies: false
    })

    global.map = this

    this.addControl(new mapboxgl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    }))
  }
}

export default SuperMap
