import Foundation
import SwiftUI
struct GamePointResponse: Decodable {
    let results: [GamePointModel]
}

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
        case id = "userId"  // Changed from user_id_id to userId to match new API
        case point
        case name = "nickname"
        case answer_time = "answerTime"  // Changed to match new API
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(point)
        hasher.combine(answer_time)
    }
    
    static func == (lhs: GamePointModel, rhs: GamePointModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.point == rhs.point &&
               lhs.answer_time == rhs.answer_time
    }
}
