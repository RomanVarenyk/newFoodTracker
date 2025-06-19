import Foundation

struct IngredientEntry: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: String = ""
}
