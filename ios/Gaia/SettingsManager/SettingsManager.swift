import Foundation

class SettingsManager {
  private let defaults = UserDefaults.standard
  
  let multicastSettingManagerDelegate = MulticastDelegate<(SettingsManagerDelegate)>()
  
  lazy var quickLayerSelect = Setting(defaults, key: "QuickLayerSelect", defaultValue: false)
  lazy var showDisabledLayers = Setting(defaults, key: "ShowDisabledLayers", defaultValue: true)
  lazy var rightHandedMenu = Setting(defaults, key: "RightHandedMenu", defaultValue: true)
  
  func settingsDidChange(){
    print("sm sdc")
    self.multicastSettingManagerDelegate.invoke(invocation: {$0.settingsDidChange()})
  }
  
  struct Setting<T> {
    private let defaults: UserDefaults
    private let key: String
    private let defaultValue: T
    
    init(_ defaults: UserDefaults, key: String, defaultValue: T) {
      self.defaults = defaults
      self.key = key
      self.defaultValue = defaultValue
    }
    
    var value: T {
      defaults.object(forKey: key) as? T ?? defaultValue
    }
    
    func set(_ newValue: T) {
      print("set", key, newValue)
      defaults.setValue(newValue, forKey: key)
    }
    
    func reset() {
      set(defaultValue)
    }
  }
  
  static let shared = SettingsManager()
}

extension SettingsManager.Setting where T == Bool {
  func toggle() {
    set(!value)
  }
}

protocol SettingsManagerDelegate {
  func settingsDidChange()
}
