import Foundation

// Format class rating from "IIItoIV" to "III - IV"
// "IVstandoutVplus" to "IV (V+)"
func formatClassRating(_ rating: String) -> String {
    var formatted = rating
    
    // Replace "to" with " - "
    formatted = formatted.replacingOccurrences(of: "to", with: " - ")
    
    // Replace "plus" with "+"
    formatted = formatted.replacingOccurrences(of: "plus", with: "+")
    
    // Replace "minus" with "-"
    formatted = formatted.replacingOccurrences(of: "minus", with: "-")
    
    // Handle "standout" - wrap everything after it in parentheses
    if let standoutRange = formatted.range(of: "standout") {
        let beforeStandout = formatted[..<standoutRange.lowerBound]
        let afterStandout = formatted[standoutRange.upperBound...]
        formatted = beforeStandout + "(" + afterStandout + ")"
    }
    
    return formatted
}
