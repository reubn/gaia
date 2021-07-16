import Foundation
import UIKit

fileprivate let timeout: Double = 1.25
fileprivate let fadeDuration: Double = 0.1
fileprivate let fadeTicksPerSecond: Double = 120
fileprivate let fallbackBrightness: CGFloat = 0.75

class BrightnessManager: SettingsManagerDelegate {
  private let screen = UIScreen.main
  
  private var managementActive: Bool {
    ProcessInfo.processInfo.isLowPowerModeEnabled && SettingsManager.shared.autoAdjustment.value
  }

  private var holds: Set<Hold> = [] {
    didSet {
      touch()
    }
  }
  
  var defaultBrightness: CGFloat?
  
  var fadeWorkItems: [DispatchWorkItem] = []
  
  init() {
    SettingsManager.shared.multicastSettingManagerDelegate.add(delegate: self)
    NotificationCenter.default.addObserver(self, selector: #selector(systemBrightnessWasChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(lowPowerModeChanged), name: .NSProcessInfoPowerStateDidChange, object: nil)
    
    touch()
  }
  
  func settingsDidChange() {
    touch()
  }
  
  func touch(){
    if !managementActive {
      return
    }
    
    if holds.isEmpty {
      enactChange(level: SettingsManager.shared.autoAdjustmentLowPoint.value, instant: false)
    } else {
      enactChange(level: defaultBrightness ?? fallbackBrightness, instant: true)
    }
  }
  
  func place(hold: Hold){
    holds.insert(hold)
    
    switch hold.type {
      case .infinite: ()
      case .finite(let time): DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
        self.holds.remove(hold)
      }
    }
  }
  
  func remove(hold: Hold){
    self.holds.remove(hold)
  }
  
  private func enactChange(level: CGFloat, instant: Bool = false){
    clearFade()
    
    if(instant) {
      screen.brightness = level
    } else {
      fade(to: level, duration: fadeDuration, ticksPerSecond: fadeTicksPerSecond)
    }
  }
  
  private func fade(to value: CGFloat, duration: TimeInterval, ticksPerSecond: Double) {
    let startingBrightness = screen.brightness
    let delta = value - startingBrightness
    let totalTicks = Int(ticksPerSecond * duration)
    let changePerTick = delta / CGFloat(totalTicks)
    let delayBetweenTicks = 1 / ticksPerSecond
    
    let time = DispatchTime.now()
    
    for i in 1...totalTicks {
      let workItem = DispatchWorkItem {
        self.screen.brightness = max(min(startingBrightness + (changePerTick * CGFloat(i)), 1), 0)
      }
      
      fadeWorkItems.append(workItem)
      
      DispatchQueue.main.asyncAfter(deadline: time + delayBetweenTicks * Double(i), execute: workItem)
    }
  }
  
  private func clearFade(){
    fadeWorkItems.forEach({$0.cancel()})
  }
  
  func capture(){
    defaultBrightness = screen.brightness
    
    touch()
  }
  
  func release(){
    if let brightness = defaultBrightness {
      enactChange(level: brightness)
      defaultBrightness = nil
    }
    
    holds = holds.filter({$0.immortal})
  }
  
  @objc func systemBrightnessWasChanged() {
    defaultBrightness = screen.brightness
  }
  
  @objc func lowPowerModeChanged() {
    DispatchQueue.main.async {[self] in
      if(ProcessInfo.processInfo.isLowPowerModeEnabled){
        touch()
      } else {
        if let brightness = defaultBrightness {
          enactChange(level: brightness)
          defaultBrightness = nil
        }
      }
    }
  }
  
  struct Hold: Equatable, Hashable {
    static func == (lhs: BrightnessManager.Hold, rhs: BrightnessManager.Hold) -> Bool {
      lhs.uuid == rhs.uuid
    }
    
    let type: HoldType
    let immortal: Bool
    
    let uuid = UUID()
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(uuid)
    }
    
    enum HoldType {
      case infinite
      case finite(Double)
    }
  }
  
  static let shared = BrightnessManager()
}

extension BrightnessManager.Hold {
  static func finite(_ time: Double = timeout, immortal: Bool = true) -> Self {
    .init(type: .finite(time), immortal: immortal)
  }
  
  static func infinite(immortal: Bool = true) -> Self {
    .init(type: .infinite, immortal: immortal)
  }
}
