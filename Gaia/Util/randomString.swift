import Foundation

func randomString(length: Int) -> String {
  let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}
