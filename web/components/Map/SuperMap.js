import mapboxgl from 'mapbox-gl/dist/mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

import MapboxDraw from '@mapbox/mapbox-gl-draw'
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css'

import length from '@turf/length'

import {accessToken} from './secret'

mapboxgl.accessToken = accessToken


const draw = new MapboxDraw({
  controls: {
    line_string: true
  },
  displayControlsDefault: false,
  styles: [
    // ACTIVE (being drawn)
    // line stroke
    {
        "id": "gl-draw-line",
        "type": "line",
        "filter": ["all", ["==", "$type", "LineString"], ["!=", "mode", "static"]],
        "layout": {
          "line-cap": "round",
          "line-join": "round"
        },
        "paint": {
          "line-color": "#5C1BF5",
          "line-opacity": 0.6988188976377951,
          // "line-dasharray": [0.2, 2],
          "line-width": ['interpolate', ['linear'], ['zoom'], 5, 3, 10, 4, 16, 5]
        }
    },
    // vertex point halos
    {
      "id": "gl-draw-polygon-and-line-vertex-halo-active",
      "type": "circle",
      "filter": ["all", ["==", "meta", "vertex"], ["==", "$type", "Point"], ["!=", "mode", "static"]],
      "paint": {
        "circle-radius": 5,
        "circle-color": "#FFF"
      }
    },
    // vertex points
    {
      "id": "gl-draw-polygon-and-line-vertex-active",
      "type": "circle",
      "filter": ["all", ["==", "meta", "vertex"], ["==", "$type", "Point"], ["!=", "mode", "static"]],
      "paint": {
        "circle-radius": 3,
        "circle-color": "#D20C0C",
      }
    },
    // polygon mid points
   {
   'id': 'gl-draw-polygon-midpoint',
   'type': 'circle',
   'filter': ['all',
     ['==', '$type', 'Point'],
     ['==', 'meta', 'midpoint']],
   'paint': {
     'circle-radius': 3,
     'circle-color': '#fbb03b'
   }
 }
  ]
})

MapboxDraw.modes.simple_select.clickOnVertex = function(state, e) {
  console.log(this, state, e)
  console.log('click', e.featureTarget)

  const feature = draw.get(e.featureTarget.properties.parent)
  const position = +e.featureTarget.properties.coord_path
  console.log(feature)

  if(!position || position === feature.geometry.coordinates.length - 1) this.changeMode('draw_line_string', {
    featureId: feature.id,
    from: feature.geometry.coordinates[position]
  })
}

class SuperMap extends mapboxgl.Map {
  constructor(options){
    super({
      ...options,
      attributionControl: false,
      renderWorldCopies: false
    })

    global.map = this



    this.addControl(draw, 'top-left')

    this.on('draw.create', ({features}) => console.log('created', features, features.map(feature => length(feature, {units: 'kilometers'}))))
    this.on('draw.update', ({features}) => console.log('updated', features, features.map(feature => length(feature, {units: 'kilometers'}))))
  }
}

export default SuperMap
