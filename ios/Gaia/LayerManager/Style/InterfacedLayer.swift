import Foundation
import Mapbox

extension Style {
  struct InterfacedLayer {
    let id: String
    let type: String
    
    let capabilities: Set<Capability>
    
    var colour: UIColor?
    var opacity: Double?
    
    let colourIsExpression: Bool
    let opacityIsExpression: Bool
    
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
      
      var rawColour: AnyCodable?
      var rawOpacity:  AnyCodable?
      var capabilities: Set<InterfacedLayer.Capability>
      
      switch type {
        case "line":
          rawColour = layer.paint?[dynamicMember: "line-color"]
          rawOpacity = layer.paint?[dynamicMember: "line-opacity"]
          capabilities = [.colour, .opacity]
        case "circle":
          rawColour = layer.paint?[dynamicMember: "circle-color"]
          rawOpacity = layer.paint?[dynamicMember: "circle-opacity"]
          capabilities = [.colour, .opacity]
        case "fill":
          rawColour = layer.paint?[dynamicMember: "fill-color"]
          rawOpacity = layer.paint?[dynamicMember: "fill-opacity"]
          capabilities = [.colour, .opacity]
        case "fill-extrusion":
          rawColour = layer.paint?[dynamicMember: "fill-extrusion-color"]
          rawOpacity = layer.paint?[dynamicMember: "fill-extrusion-opacity"]
          capabilities = [.colour, .opacity]
        case "background":
          rawColour = layer.paint?[dynamicMember: "background-color"]
          rawOpacity = layer.paint?[dynamicMember: "background-opacity"]
          capabilities = [.colour, .opacity]
        case "symbol":
          if layer.layout?[dynamicMember: "text-field"] != nil {
            rawColour = layer.paint?[dynamicMember: "text-color"]
            rawOpacity = layer.paint?[dynamicMember: "text-opacity"]
          } else {
            rawColour = layer.paint?[dynamicMember: "icon-color"]
            rawOpacity = layer.paint?[dynamicMember: "icon-opacity"]
          }
          capabilities = [.colour, .opacity]
        case "raster":
          rawOpacity = layer.paint?[dynamicMember: "raster-opacity"]
          capabilities = [.opacity]
        case "heatmap":
          rawOpacity = layer.paint?[dynamicMember: "heatmap-opacity"]
          capabilities = [.opacity]
        default: capabilities = []
      }
      
      var opacityIsExpression = false
      let opacityValue: Double? = {
        guard let anyCodable = rawOpacity else {
          return nil
        }
        
        if let number = anyCodable.value as? NSNumber {
          return number.doubleValue
        }
        
        if anyCodable.value as? [Any] != nil {
          opacityIsExpression = true
        }
        
        return nil
      }()
      
      var opacityFromColourValue: Double = 1
      
      var colourIsExpression = false
      let colourBeforeOpacityModification: UIColor? = {
        guard let anyCodable = rawColour else {
          return nil
        }
        
        if let css = anyCodable.value as? String {
          guard let uiColor = UIColor(css: css) else {
            return nil
          }
 
          opacityFromColourValue = Double(uiColor.components?.alpha ?? 1)
          
          return uiColor
        }
        
        if let expression = anyCodable.value as? [Any] {
          colourIsExpression = true
          
          return expression.firstMap({
            guard let css = $0 as? String else {
              return nil
            }
            
            return UIColor(css: css)
          })
        }
        
        return nil
      }()
      
      let opacity = opacityValue ?? opacityFromColourValue
      let colour = colourBeforeOpacityModification?.withAlphaComponent(CGFloat(opacity))
      
      let interfacedLayer = InterfacedLayer(
        id: id,
        type: type,
        capabilities: capabilities,
        colour: colour,
        opacity: opacity,
        colourIsExpression: colourIsExpression,
        opacityIsExpression: opacityIsExpression
      )
      interfacedLayersCache[hashValue] = interfacedLayer
      
      return interfacedLayersCache[hashValue]
    }
    
    enum Capability: CaseIterable {
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
            case "fill-extrusion": copy.layers[index].paint?[dynamicMember: "fill-extrusion-color"] = colourString
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
            case "fill-extrusion": copy.layers[index].paint?[dynamicMember: "fill-extrusion-opacity"] = AnyCodable(opacity)
            case "background": copy.layers[index].paint?[dynamicMember: "background-opacity"] = AnyCodable(opacity)
            case "heatmap": copy.layers[index].paint?[dynamicMember: "heatmap-opacity"] = AnyCodable(opacity)
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
