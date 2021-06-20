import Foundation
import Mapbox

extension Style {
  struct InterfacedLayer {
    let id: String
    
    let capabilities: Set<Capability>
    
    var colour: UIColor?
    var opacity: Double?
    
    func setting(_ capability: Capability, to: Any?) -> Self{
      var copy = self
      
      if capabilities.contains(capability) {
        switch capability {
          case .colour: copy.colour = to as! UIColor?
          case .opacity: copy.opacity = to as! Double?
        }
      }
      
      return copy
    }
    
    static func create(_ layer: Layer) -> Self? {
      let hashValue = layer.hashValue
      
      if let cached = interfacedLayersCache[hashValue] {
        return cached
      }
      
      guard let type = layer.type?.value as? String,
            let id = layer.id?.value as? String else {
        return nil
      }
      
      print("InterfacedLayer", id)
      
      var hex: String?
      var rawOpacity: NSNumber?
      var capabilities: Set<InterfacedLayer.Capability>
      
      switch type {
        case "line":
          hex = layer.paint?[dynamicMember: "line-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "line-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "circle":
          hex = layer.paint?[dynamicMember: "circle-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "circle-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "fill":
          hex = layer.paint?[dynamicMember: "fill-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "fill-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "background":
          hex = layer.paint?[dynamicMember: "background-color"]?.value as? String
          rawOpacity = layer.paint?[dynamicMember: "background-opacity"]?.value as? NSNumber
          capabilities = [.colour, .opacity]
        case "symbol":
          if layer.layout?[dynamicMember: "text-field"] != nil {
            hex = layer.paint?[dynamicMember: "text-color"]?.value as? String
            rawOpacity = layer.paint?[dynamicMember: "text-opacity"]?.value as? NSNumber
          } else {
            hex = layer.paint?[dynamicMember: "icon-color"]?.value as? String
            rawOpacity = layer.paint?[dynamicMember: "icon-opacity"]?.value as? NSNumber
          }
          
          capabilities = [.colour, .opacity]
        case "raster":
          rawOpacity = layer.paint?[dynamicMember: "raster-opacity"]?.value as? NSNumber
          capabilities = [.opacity]
        default: capabilities = []
      }
      
      let opacity = rawOpacity?.doubleValue
      let colour = hex != nil ? UIColor(hex: hex!)?.withAlphaComponent(CGFloat(opacity ?? 1)) : nil
      
      let interfacedLayer = InterfacedLayer(id: id, capabilities: capabilities, colour: colour, opacity: opacity)
      interfacedLayersCache[hashValue] = interfacedLayer
      
      return interfacedLayersCache[hashValue]
    }
    
    enum Capability {
      case colour
      case opacity
    }
  }
  
  func with(_ layerOptions: [InterfacedLayer]) -> Self {
    var copy = self
    
    for desc in layerOptions {
      if let index = copy.layers.firstIndex(where: {$0.id?.value as? String == desc.id}),
         let type = copy.layers[index].type?.value as? String {
        let hashValue = copy.layers[index].hashValue
        interfacedLayersCache.removeValue(forKey: hashValue)
        
        copy.layers[index].paint = copy.layers[index].paint ?? AnyCodable([:])
        
        if let colour = desc.colour,
           let hex = colour.toHex() {
          let colourString = AnyCodable("#" + hex)
          switch type {
            case "line": copy.layers[index].paint?[dynamicMember: "line-color"] = colourString
            case "circle": copy.layers[index].paint?[dynamicMember: "circle-color"] = colourString
            case "fill": copy.layers[index].paint?[dynamicMember: "fill-color"] = colourString
            case "background": copy.layers[index].paint?[dynamicMember: "background-color"] = colourString
            case "symbol":
              let property = copy.layers[index].layout?[dynamicMember: "text-field"] != nil ? "text-color" : "icon-color"
              copy.layers[index].paint?[dynamicMember: property] = colourString
            default: ()
          }
        }
        
        if let opacity = desc.opacity ?? {let o = desc.colour?.components?.alpha; return o != nil ? Double(o!) : nil}() {
          switch type {
            case "raster": copy.layers[index].paint?[dynamicMember: "raster-opacity"] = AnyCodable(opacity)
            case "line": copy.layers[index].paint?[dynamicMember: "line-opacity"] = AnyCodable(opacity)
            case "circle": copy.layers[index].paint?[dynamicMember: "circle-opacity"] = AnyCodable(opacity)
            case "fill": copy.layers[index].paint?[dynamicMember: "fill-opacity"] = AnyCodable(opacity)
            case "background": copy.layers[index].paint?[dynamicMember: "background-opacity"] = AnyCodable(opacity)
            case "symbol":
              let property = copy.layers[index].layout?[dynamicMember: "text-field"] != nil ? "text-opacity" : "icon-opacity"
              copy.layers[index].paint?[dynamicMember: property] = AnyCodable(opacity)
            default: ()
          }
        }
        
      }
    }
    
    return copy
  }
}
