import Foundation

extension CharacterSet {
  static var urlAllowedCharacters: CharacterSet {
    // Start by including hash, which isn't in any set
    var characters = CharacterSet(charactersIn: "#")
    
    // All URL-legal characters
    characters.formUnion(.urlUserAllowed)
    characters.formUnion(.urlPasswordAllowed)
    characters.formUnion(.urlHostAllowed)
    characters.formUnion(.urlPathAllowed)
    characters.formUnion(.urlQueryAllowed)
    characters.formUnion(.urlFragmentAllowed)
    
    return characters
  }
}
