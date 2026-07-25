import Foundation
import SwiftData

@Model
final class CapacityCheckIn {
    var id: UUID
    var date: Date
    var energy: Int
    var stress: Int
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        energy: Int,
        stress: Int,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.energy = energy
        self.stress = stress
        self.note = note
    }
}
