import Foundation

struct Debounce {
  let time: Double
  let handler: () -> ()
  
  private var task: DispatchWorkItem?
  
  init(time: Double, handler: @escaping () -> ()) {
    self.time = time
    self.handler = handler
  }
  
  mutating func go() {
    task?.cancel()
    
    task = DispatchWorkItem(block: handler)
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time, execute: task!)
  }
}
