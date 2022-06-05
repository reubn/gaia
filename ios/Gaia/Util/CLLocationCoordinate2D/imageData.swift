import Foundation
import CoreLocation
import ImageIO

extension CLLocationCoordinate2D {
  init?(image: Data) {
    if let source = CGImageSourceCreateWithData(image as CFData, nil),
       let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
       let gpsData = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any],
       let longitude = gpsData[kCGImagePropertyGPSLongitude] as? Double,
       let latitude = gpsData[kCGImagePropertyGPSLatitude] as? Double,
       let longitudeRef =  gpsData[kCGImagePropertyGPSLongitudeRef] as? String,
       let latitudeRef =  gpsData[kCGImagePropertyGPSLatitudeRef] as? String {
      self.init()
      self.latitude = latitudeRef == "N" ? latitude : -latitude
      self.longitude = longitudeRef == "E" ? longitude : -longitude
      
      if(!CLLocationCoordinate2DIsValid(self)) {
        return nil
      }
    } else {
      return nil
    }
  }
}
