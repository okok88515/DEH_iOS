import Foundation
import SwiftUI

class GamePointModel: Decodable, Hashable, Identifiable {
    var correctness: Bool
    var id: Int
    var point: Int
    var name: String
    var answer_time: String
    
    init(correctness: Bool, id: Int, point: Int, nickname: String, answer_time: String) {
        self.correctness = correctness
        self.id = id
        self.point = point
        self.name = nickname
        self.answer_time = answer_time
    }
    
    enum CodingKeys: String, CodingKey {
        case correctness
        case id = "user_id_id"
        case point
        case name = "nickname"
        case answer_time
    }
    
    // Original hash function only used id, which made different points with same user appear as duplicates
    // Adding point and answer_time to ensure each game attempt is unique, even from same user
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(point)  // Add point to make each item unique
        hasher.combine(answer_time)  // Add answer_time to make each item unique
    }
    
    // Original equality only compared IDs, causing SwiftUI to treat different attempts from same user as identical
    // Updated to compare all relevant properties to properly distinguish between attempts
    static func == (lhs: GamePointModel, rhs: GamePointModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.point == rhs.point &&
               lhs.answer_time == rhs.answer_time
    }
}
