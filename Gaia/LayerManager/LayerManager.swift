import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  let mapView: MGLMapView
  var groups: [String: [Layer]]?
  var magicLayers: [Layer]?

  let multicastMapViewRegionIsChangingDelegate = MulticastDelegate<(LayerCell)>()
  let multicastLayersHaveChangedDelegate = MulticastDelegate<(Section)>()

  let layerGroups = [
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(id: "base", name: "Base Maps", colour: .systemBlue)
  ]
  
  var layers: [Layer]{
    get {
      var layers: [Layer] = []

      for (_, group) in groups! {
        layers.append(contentsOf: group)
      }

      return layers
    }
  }

  var activeLayers: [Layer]{
    get {
      layers.filter({$0.enabled})
    }
  }

  var sortedLayers: [Layer]{
    get {
      activeLayers.sorted(by: layerSortingFunction)
    }
  }

  func layerSortingFunction(a: Layer, b: Layer) -> Bool {
    if(a.group! != b.group!) {
      return layerGroups.firstIndex(where: {layerGroup in a.group! == layerGroup.id}) ?? 0 > layerGroups.firstIndex(where: {layerGroup in b.group! == layerGroup.id}) ?? 0
    }
    
    if(a.groupIndex != b.groupIndex) {return a.groupIndex > b.groupIndex}
    
    return a.name! > b.name!
  }

  init(mapView: MGLMapView){
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    self.managedContext = appDelegate!.persistentContainer.viewContext

    self.mapView = mapView
    clearData()
    createData()
    loadData()
  }

  func loadData() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Layer")

    do {
      let results = try managedContext.fetch(fetchRequest) as! [Layer]

      let unorderedGroups = Dictionary(grouping: results) { (obj) -> String in
        return obj.group!
      }

      groups = unorderedGroups.mapValues({
        $0.sorted(by: layerSortingFunction)
      })
//      print("items saved", groups!.count)

    } catch {print("Failed")}
  }

  func clearData(){
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Layer")
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

    do {
      try managedContext.execute(batchDeleteRequest)
    } catch {
        print("Detele all data in error :", error)
    }
  }

  func createData(){

    let layerA = Layer.init(context: managedContext)
    layerA.id = "stravaA"
    layerA.name = "Strava Heatmap Run"
    layerA.group = "overlay"
    layerA.url = "https://r3.cedar/strava/run/hot/{z}/{x}/{y}"
    layerA.enabled = true
    layerA.groupIndex = 2

    let layerAB = Layer.init(context: managedContext)
    layerAB.id = "stravaB"
    layerAB.name = "Strava Heatmap Ride"
    layerAB.group = "overlay"
    layerAB.url = "https://r3.cedar/strava/ride/purple/{z}/{x}/{y}"
    layerAB.enabled = true
    layerAB.groupIndex = 1

    let layerAC = Layer.init(context: managedContext)
    layerAC.id = "stravaC"
    layerAC.name = "Strava Heatmap Water"
    layerAC.group = "overlay"
    layerAC.url = "https://r3.cedar/strava/water/blue/{z}/{x}/{y}"
    layerAC.enabled = true
    layerAC.groupIndex = 0

    let layerB = Layer.init(context: managedContext)
    layerB.id = "magicOS"
    layerB.name = "Ordnanace Survey"
    layerB.group = "base"
    layerB.url = "https://r3.cedar/magicOS/{z}/{x}/{y}"
    layerB.tileSize = "200"
    layerB.enabled = true
    layerB.groupIndex = 0

    let layerC = Layer.init(context: managedContext)
    layerC.id = "bingSat"
    layerC.name = "Bing Satellite"
    layerC.group = "aerial"
    layerC.url = "https://r3.cedar/bingSat/{z}/{x}/{y}"
    layerC.tileSize = "128"
    layerC.enabled = false
    layerC.groupIndex = 0

    let layerD = Layer.init(context: managedContext)
    layerD.id = "osm"
    layerD.name = "OpenStreetMap"
    layerD.group = "base"
    layerD.url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    layerD.tileSize = "128"
    layerD.enabled = false
    layerD.groupIndex = 0

    let layerE = Layer.init(context: managedContext)
    layerE.id = "googleSat"
    layerE.name = "Google Satellite"
    layerE.group = "aerial"
    layerE.url = "https://r3.cedar/googleSat/{z}/{x}/{y}"
    layerE.tileSize = "128"
    layerE.enabled = false
    layerE.groupIndex = 0

    let layerF = Layer.init(context: managedContext)
    layerF.id = "osSat2017"
    layerF.name = "Ordnance Survey"
    layerF.group = "aerial"
    layerF.url = "https://r3.cedar/osSat2017/{z}/{x}/{y}"
    layerF.tileSize = "128"
    layerF.enabled = false
    layerF.groupIndex = 0

    do {try managedContext.save()}
    catch let error as NSError {print("Could not save. \(error), \(error.userInfo)")}
  }

  func uiShouldBeDark() -> Bool {
    let topNonOverlay = sortedLayers.reversed().first(where: {$0.group != "overlay"})

    if(topNonOverlay == nil) {return true}

    return topNonOverlay!.group == "aerial"
  }

  func apply() {
    mapView.styleURL = generateStyleURL(sortedLayers: sortedLayers)

    DispatchQueue.main.async { [self] in
      let dark = uiShouldBeDark()
      mapView.window?.overrideUserInterfaceStyle = dark ? .dark : .light
      mapView.window?.tintColor = dark ? .white : .systemBlue
    }
  }

  func updateLayers(){
    apply()
    multicastLayersHaveChangedDelegate.invoke(invocation: {$0.layersHaveChanged()})
    do {
        try managedContext.save()
    } catch {
        print("saving error :", error)
    }
  }

  func enableLayer(layer: Layer) {
    if(layer.group == "overlay") {
      layer.enabled = true
    } else {
      for _layer in layers {
        if(_layer.group != "overlay") {
          _layer.enabled = _layer == layer
        }
      }
    }

    updateLayers()
  }

  func disableLayer(layer: Layer) {
    layer.enabled = false

    updateLayers()
  }

  public func getLayers(layerGroup: LayerGroup) -> [Layer]? {
    groups![layerGroup.id]
  }

  public func magic(){
    let overlayGroup = layerGroups.first(where: {$0.id == "overlay"})!
    let overlayLayers = getLayers(layerGroup: overlayGroup)!

    let activeOverlayLayers = overlayLayers.filter({$0.enabled})
    if(activeOverlayLayers.count > 0) {
      // active overlays, capture
      magicLayers = activeOverlayLayers

      // and hide them
      activeOverlayLayers.forEach({
        disableLayer(layer: $0)
      })
    } else {
      // no active overlays, restore
      (magicLayers ?? overlayLayers).forEach({
        enableLayer(layer: $0)
      })

      magicLayers = nil
    }
  }

  public func generateStyleURL(sortedLayers: [Layer]) -> URL {
    if(groups == nil) {return Bundle(for: LayerManager.self).url(forResource: "noAccessToken", withExtension: "json")!}

    let layerSourcesJSON = sortedLayers.reduce(into: [String: LayerSourceJSON]()) {
      let incoming = $1 as Layer
      $0[$1.id!] = LayerSourceJSON(
        type: LayerTypeJSON.raster,
        tiles: [incoming.url!],
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!),
        tileSize: (incoming.tileSize ?? "").isEmpty ? 256 : Int(incoming.tileSize!)
      )
    }

    let layerLayersJSON: [LayerLayerJSON] = sortedLayers.map {
      let incoming = $0 as Layer

      return LayerLayerJSON(
        id: incoming.id!,
        type: LayerTypeJSON.raster,
        source: incoming.id!,
        minzoom: (incoming.minZoom ?? "").isEmpty ? nil : Int(incoming.minZoom!),
        maxzoom: (incoming.maxZoom ?? "").isEmpty ? nil : Int(incoming.maxZoom!)
      )
    }

    let rootJSON = StyleJSON(sources: layerSourcesJSON, layers: layerLayersJSON)

    do {
      let encoder = JSONEncoder()

      let data = try encoder.encode(rootJSON)
      let json = String(data: data, encoding: .utf8)!

      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

      let temporaryFilename = ProcessInfo().globallyUniqueString

      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

      try data.write(to: temporaryFileURL, options: .atomic)

      return temporaryFileURL
    } catch {
      return Bundle(for: LayerManager.self).url(forResource: "noAccessToken", withExtension: "json")!
    }
  }
}

struct LayerGroup {
  let id: String
  let name: String
  let colour: UIColor
}

enum LayerTypeJSON: String, Codable {
  case vector, raster
}

struct LayerSourceJSON: Codable {
  let type: LayerTypeJSON
  let tiles: [String]

  let minzoom: Int?
  let maxzoom: Int?
  let tileSize: Int?
}

struct LayerLayerJSON: Codable {
  let id: String
  let type: LayerTypeJSON
  let source: String

  let minzoom: Int?
  let maxzoom: Int?
}

struct StyleJSON: Codable {
  var version = 8
  let sources: [String: LayerSourceJSON]
  let layers: [LayerLayerJSON]
}
