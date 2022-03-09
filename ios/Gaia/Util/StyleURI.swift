import Foundation

@_spi(Experimental)import MapboxMaps

extension StyleURI {
  var url: URL? {
    URL(string: rawValue)
  }
}
