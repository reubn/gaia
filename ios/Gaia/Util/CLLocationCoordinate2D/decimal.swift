//
//  decimal.swift
//  Gaia
//
//  Created by Reuben Eggar on 27/03/2022.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
  init?(decimal: String) {
    let coords = decimal
      .components(separatedBy: .whitespacesAndNewlines.union(.init(charactersIn: ",")))
      .compactMap({Double($0.trimmingCharacters(in: .whitespacesAndNewlines))})
    
    if(coords.count == 2) {
      self.init()
      
      self.latitude = coords[0]
      self.longitude = coords[1]
      
      if(!CLLocationCoordinate2DIsValid(self)) {
        self.latitude = coords[1]
        self.longitude = coords[0]
      }
      
      if(!CLLocationCoordinate2DIsValid(self)) {
        return nil
      }
    }
    
    return nil
  }
}
