import Foundation
import CoreData

import Mapbox

class LayerManager {
  private let managedContext: NSManagedObjectContext
  let mapView: MGLMapView
  var groups: [String: [Layer]]?

  let multicastMapViewRegionIsChangingDelegate = MulticastDelegate<(LayerCell)>()

  let layerGroups = [
    LayerGroup(id: "overlay", name: "Overlays", colour: .systemPink),
    LayerGroup(id: "aerial", name: "Aerial Imagery", colour: .systemGreen),
    LayerGroup(id: "base", name: "Base Maps", colour: .systemBlue)
  ]
  
  var activeLayers: [Layer]{
    get {
      var activeLayers: [Layer] = []

      for (_, group) in groups! {
        activeLayers.append(contentsOf: group.filter({$0.enabled}))
      }
      
      return activeLayers
    }
  }
  
  var sortedLayers: [Layer]{
    get {
      activeLayers.sorted(by: {a, b in
        // if($0.type! == $1.type!) {return $0.layerIndex < $1.layerIndex}
        return layerGroups.firstIndex(where: {layerGroup in a.group! == layerGroup.id}) ?? 0 > layerGroups.firstIndex(where: {layerGroup in b.group! == layerGroup.id}) ?? 0
      })
    }
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

      groups = Dictionary(grouping: results) { (obj) -> String in
        return obj.group!
      }
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
    let layerB = Layer.init(context: managedContext)
    layerB.id = "magicOS"
    layerB.name = "Ordnanace Survey"
    layerB.group = "base"
    layerB.url = "https://r3.cedar/magicOS/{z}/{x}/{y}"
    layerB.tileSize = "200"
    layerB.enabled = true

    let layerA = Layer.init(context: managedContext)
    layerA.id = "strava"
    layerA.name = "Strava Heatmap"
    layerA.group = "overlay"
    layerA.url = "https://r3.cedar/strava/{z}/{x}/{y}"
    layerA.enabled = true

    let layerC = Layer.init(context: managedContext)
    layerC.id = "bingSat"
    layerC.name = "Bing Satellite"
    layerC.group = "aerial"
    layerC.url = "https://r3.cedar/bingSat/{z}/{x}/{y}"
    layerC.tileSize = "128"
    layerC.enabled = false

    let layerD = Layer.init(context: managedContext)
    layerD.id = "osm"
    layerD.name = "OpenStreetMap"
    layerD.group = "base"
    layerD.url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    layerD.tileSize = "128"
    layerD.enabled = true

    let layerE = Layer.init(context: managedContext)
    layerE.id = "googleSat"
    layerE.name = "Google Satellite"
    layerE.group = "aerial"
    layerE.url = "https://r3.cedar/googleSat/{z}/{x}/{y}"
    layerE.tileSize = "128"
    layerE.enabled = false

    let layerF = Layer.init(context: managedContext)
    layerF.id = "osSat2017"
    layerF.name = "Ordnance Survey"
    layerF.group = "aerial"
    layerF.url = "https://r3.cedar/osSat2017/{z}/{x}/{y}"
    layerF.tileSize = "128"
    layerF.enabled = false

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
      mapView.window?.overrideUserInterfaceStyle = uiShouldBeDark() ? .dark : .light
    }
  }

  func updateLayers(){
    apply()
    do {
        try managedContext.save()
    } catch {
        print("saving error :", error)
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
