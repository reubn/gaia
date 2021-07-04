import {useState, useEffect, useRef} from 'react'
import Layer from './Layer'
import CompositeStyle from './CompositeStyle'

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
  groups = groups

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

  useLayerManager(){
    const [state, setState] = useState(0)
    const handler = useRef(() => setState(Math.random()))

    useEffect(() => {
      handler.current()
      this.addEventListener(layersUpdated, handler.current)

      return () => this.removeEventListener(layersUpdated, handler.current)
    }, [])

    return state
  }

  async import(url){
    const res = await fetch(url)
    const json = await res.json()

    json.forEach(layerDefinition => this.accept(layerDefinition))
  }

  accept(layerDefinition){
    const layer = Layer.fromLayerDefinition(layerDefinition)
    console.log(layer)
    this.layers.push(layer)
    this.save()
  }

  layerSortingFunction(a, b) {
    return (() => {
      if(a.isOpaque != b.isOpaque) {
        return b.isOpaque
      }

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

  show(layer, mutuallyExclusive) {
    console.log(layer)
   if(!layer.isOpaque || !mutuallyExclusive) {
     layer.visible = true
   } else {
     for(let _layer of this.layers) {
       if(_layer.isOpaque) _layer.visible = _layer == layer
     }
   }

   this.save()

   return true
 }

 hide(layer, mutuallyExclusive) {
   if(!layer.isOpaque || !mutuallyExclusive || this.visibleLayers.filter(layer => layer.isOpaque).count > 1) {
     layer.visible = false
     this.save()

     return true
   }

   return false
 }

 get visibleLayers(){
   return this.layers.filter(({visible}) => visible)
 }

 get compositeStyle(){
   return new CompositeStyle(this.visibleLayers.sort(this.layerSortingFunction))
 }
}

const layerManager = typeof window !== 'undefined' ? new LayerManager() : undefined
global.layerManager = layerManager

export default layerManager
