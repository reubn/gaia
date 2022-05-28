import MapboxDraw from '@mapbox/mapbox-gl-draw'
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css'

import length from '@turf/length'

const colours = ['#fe3e5e','#ffed61','#ffc233','#3dfa7c','#5aedc8','#4dcfff','#fc277c','#f05','#c34ef9','#952ef5','#5252ff']

const geoJSON = JSON.parse(global.localStorage?.getItem('geoJSON') ?? '{}') || {}

export const draw = new MapboxDraw({
  // controls: {
  //   line_string: true,
  //   trash: true
  // },
  // displayControlsDefault: false,
  userProperties: true,
  styles: [
    {
      'id': 'points-are-blue',
      'type': 'circle',
      'filter': ['all',
        ['==', '$type', 'Point'],
        ['==', 'meta', 'feature'],
        ['==', 'active', 'false']],
      'paint': {
        'circle-radius': 4,
        'circle-color': "#5C1BF5",
        "circle-opacity": 0.6988188976377951,
      }
    },
    {
      'id': 'highlight-active-points',
      'type': 'circle',
      'filter': ['all',
        ['==', '$type', 'Point'],
        ['==', 'meta', 'feature'],
        ['==', 'active', 'true']],
        'paint': {
          'circle-radius': 4,
          'circle-color': "#D20C0C",
          "circle-opacity": 0.6988188976377951,
        }
    },
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
          "line-color": [
            "get",
            "user_colour"
          ],
          "line-opacity": 0.6988188976377951,
          // "line-dasharray": [0.2, 2],
          "line-width": 5
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

  if(!position || position === feature.geometry.coordinates.length - 1) {
    this.changeMode('draw_line_string', {
      featureId: feature.id,
      from: feature.geometry.coordinates[position]
    })
  } else this.changeMode('direct_select', {
    featureId: feature.id
  })
}

const routeUpdate = (map, mode, {features: [feature]}) => {
  if(mode === 'create') {
    feature.properties = {
      ...feature.properties,
      colour: colours[Math.ceil(Math.random() * (colours.length - 1))]
    }

    draw.add(feature)
  }

  if(mode === 'delete') delete geoJSON[feature.id]
  else geoJSON[feature.id] = feature

  localStorage.setItem('geoJSON', JSON.stringify(geoJSON))
}


export default map => {
  map.once('sourcedata', () => Object.values(geoJSON).forEach(feature => draw.add(feature)))

  map.addControl(draw, 'top-left')

  const boundRouteUpdate = mode => (...args) => routeUpdate(map, mode, ...args)

  map.on('draw.create', boundRouteUpdate('create'))
  map.on('draw.update', boundRouteUpdate('update'))
  map.on('draw.delete', boundRouteUpdate('delete'))

  map.on('draw.selectionchange', ({features: [feature]}) => {
    if(!feature) return

    function download({filename, mime, content}) {
      const element = document.createElement('a')
      element.setAttribute('href', `data:${mime};charset=utf-8,${encodeURIComponent(content)}`)
      element.setAttribute('download', filename)

      element.style.display = 'none'
      document.body.appendChild(element)

      element.click()
      document.body.removeChild(element)
    }

    const devToolLink = {
    get downloadGeoJSON() {
        download({filename: `${feature.id}.geojson`, mime: 'application/geo+json', content: JSON.stringify(feature)})
      }
    }
    console.log(feature, length(feature, {units: 'kilometers'}), devToolLink)
  })
}
