import Foundation

@_spi(Experimental)import MapboxMaps

class GaiaMapView: MapView {
  var multicastUserTrackingModeDidChangeDelegate = MulticastDelegate<(UserTrackingModeDidChangeDelegate)>()
  
  var userTrackingMode: UserTrackingMode {
    get {
      var isFollowing = false
      
      switch viewport.status {
        case .state(let state) where state is FollowPuckViewportState: isFollowing = true
        case .transition(_, toState: let state) where state is FollowPuckViewportState: isFollowing = true
        default: ()
      }
      
      if(isFollowing) {
        return location.options.puckBearingEnabled ? .followWithHeading : .follow
      }
      
      return .none
    }
    
    set(newMode) {
      self.multicastUserTrackingModeDidChangeDelegate.invoke(invocation: {$0.userTrackingModeDidChange(to: newMode)})
      
      switch newMode {
        case .none:
          location.options.puckType = nil
          location.options.puckBearingEnabled = false
          
          camera.ease(to: .init(bearing: 0), duration: 0.3)
          location.locationProvider.stopUpdatingHeading()
          
          if(ProcessInfo.processInfo.isLowPowerModeEnabled){
            location.locationProvider.stopUpdatingLocation()
            tintColor = .systemGray
          }
          
          viewport.idle()
        case .follow:
          location.options.puckType = makePuck(showBearing: false)
          location.options.puckBearingEnabled = false
          
          camera.ease(to: .init(bearing: 0), duration: 0.3)
          location.locationProvider.stopUpdatingHeading()
          location.locationProvider.startUpdatingLocation()
          tintColor = .systemPink
          
          viewport.transition(to: makeViewportState(withBearing: false), transition: makeDefaultTransition())
        case .followWithHeading:
          location.options.puckType = makePuck(showBearing: true)
          location.options.puckBearingEnabled = true
          
          location.locationProvider.startUpdatingHeading()
          location.locationProvider.startUpdatingLocation()
          tintColor = .systemPink
          
          viewport.transition(to: makeViewportState(withBearing: true), transition: makeDefaultTransition())
      }
    }
  }
  
  func resetGestures(){
    gestures.options.panEnabled = true
    gestures.options.pinchRotateEnabled = true
    gestures.options.pinchPanEnabled = true
    gestures.options.pitchEnabled = true
    gestures.options.focalPoint = nil
  }
  
  fileprivate func makeDefaultTransition() -> ViewportTransition {
    viewport.makeDefaultViewportTransition()
  }
  
  fileprivate func makeViewportState(withBearing: Bool = false) -> ViewportState {
    viewport.makeFollowPuckViewportState(
      options: FollowPuckViewportStateOptions(
        bearing: withBearing ? .heading : nil,
        pitch: 0,
        animationDuration: 0.5
      )
    )
  }
  
  fileprivate func makePuck(showBearing: Bool = false) -> PuckType {
    var config: Puck2DConfiguration = .makeDefault(showBearing: showBearing)
    config.showsAccuracyRing = true
    
    return .puck2D(config)
  }
}

protocol UserTrackingModeDidChangeDelegate {
  func userTrackingModeDidChange(to: UserTrackingMode)
}

enum UserTrackingMode {
  case none
  case follow
  case followWithHeading
}
