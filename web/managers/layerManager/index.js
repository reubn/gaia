import {useState, useEffect, useRef} from 'react'
import Layer from './Layer'

const ET = typeof window !== 'undefined' ? EventTarget : Object

const localStorageKey = 'layers'
const layersUpdated = 'layers_updated'

const groups = [
  {id: "gpx", name: "GPX", colour: 'systemTeal', icon: "point.fill.topleft.down.curvedto.point.fill.bottomright.up"},
  {id: "overlay", name: "Overlays", colour: 'systemPink', icon: "highlighter"},
  {id: "aerial", name: "Aerial", colour: 'systemGreen', icon: "airplane"},
  {id: "base", name: "Base", colour: 'systemBlue', icon: "map"},
  {id: "historic", name: "Historic", colour: 'brown', icon: "clock.arrow.circlepath"},
]

class LayerManager extends ET {
  groups

  constructor(){
    super()
    this.layers = this.read()
  }

  read(){
    return (JSON.parse(localStorage.getItem(localStorageKey)) || []).map(layer => new Layer(layer))
  }

  save(){
    localStorage.setItem(localStorageKey, JSON.stringify(this.layers))

    this.dispatchEvent(new Event(layersUpdated))
  }

  useLayers(){
    const [state, setState] = useState([])
    const handler = useRef(() => setState([...this.layers]))

    useEffect(() => {
      handler.current()
      this.addEventListener(layersUpdated, handler.current)

      return () => this.removeEventListener(layersUpdated, handler.current)
    }, [])

    return state
  }

  layerSortingFunction(a, b) {
    return (() => {
      if(a.group != b.group) {
        return (groups.findIndex(layerGroup => a.group == layerGroup.id) || 0) < (groups.findIndex(layerGroup => b.group == layerGroup.id) || 0)
      }

      if(a.enabled != b.enabled) {
        return a.enabled // sort disabled layers below within same group
      }

      if(a.groupIndex != b.groupIndex) {
        return a.groupIndex < b.groupIndex
      }

      return a.name < b.name
    })() ? 1 : -1
  }
}

const layerManager = typeof window !== 'undefined' ? new LayerManager() : undefined
global.layerManager = layerManager

export default layerManager
