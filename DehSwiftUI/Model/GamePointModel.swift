struct GamePointResponse: Decodable {
    let results: [GamePointModel]
}

class GamePointModel: Decodable, Hashable, Identifiable {
    let chestId: Int
    let question: String?
    let answer: String?
    let questionType: Int?
    let option1: String?
    let option2: String?
    let option3: String?
    let option4: String?
    let correctness: Bool
    let point: Int?
    let recordId: Int
    var questionATT: [MediaAttachment]?
    var recordATT: [MediaAttachment]?
    
    enum CodingKeys: String, CodingKey {
        case chestId
        case question
        case answer
        case questionType
        case option1
        case option2
        case option3
        case option4
        case correctness
        case point
        case recordId
        case questionATT
        case recordATT
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chestId)
        hasher.combine(recordId)
    }
    
    static func == (lhs: GamePointModel, rhs: GamePointModel) -> Bool {
        return lhs.chestId == rhs.chestId &&
               lhs.recordId == rhs.recordId
    }
}
