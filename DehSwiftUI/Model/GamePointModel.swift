import Foundation

struct GamePointResponse: Decodable {
    let results: [GamePointModel]
}

struct GameMediaAttachment: Codable, Hashable {
    let mediaUrl: String?
    let mediaFormat: Int?
    
    enum CodingKeys: String, CodingKey {
        case mediaUrl
        case mediaFormat
    }
    
    // Convert backend format to your app's format enum
    var format: DEH_Mini_II.format {  // Explicitly reference the module
        guard let mediaFormat = mediaFormat else { return .Default }
        return DEH_Mini_II.format(rawValue: mediaFormat) ?? .Default
    }
}

class GamePointModel: Decodable, Hashable, Identifiable {
    let eventRecordHistoryId: Int
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
    var questionATT: [GameMediaAttachment]?
    var recordATT: [GameMediaAttachment]?
    
    enum CodingKeys: String, CodingKey {
        case eventRecordHistoryId = "eventChestHistoryId"
        case question
        case answer
        case questionType = "questionType"
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        eventRecordHistoryId = try container.decode(Int.self, forKey: .eventRecordHistoryId)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        answer = try container.decodeIfPresent(String.self, forKey: .answer)
        questionType = try container.decodeIfPresent(Int.self, forKey: .questionType)
        option1 = try container.decodeIfPresent(String.self, forKey: .option1)
        option2 = try container.decodeIfPresent(String.self, forKey: .option2)
        option3 = try container.decodeIfPresent(String.self, forKey: .option3)
        option4 = try container.decodeIfPresent(String.self, forKey: .option4)
        correctness = try container.decode(Bool.self, forKey: .correctness)
        point = try container.decodeIfPresent(Int.self, forKey: .point)
        recordId = try container.decode(Int.self, forKey: .recordId)
        questionATT = try container.decodeIfPresent([GameMediaAttachment].self, forKey: .questionATT)
        recordATT = try container.decodeIfPresent([GameMediaAttachment].self, forKey: .recordATT)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(eventRecordHistoryId)
        hasher.combine(recordId)
    }
    
    static func == (lhs: GamePointModel, rhs: GamePointModel) -> Bool {
        return lhs.eventRecordHistoryId == rhs.eventRecordHistoryId &&
               lhs.recordId == rhs.recordId
    }
    
    // Helper method to convert GameMediaAttachment to MediaMulti
    @MainActor  // Since MediaMulti involves UI components
    func getMediaMulti(from attachment: GameMediaAttachment) async -> MediaMulti? {
        guard let urlString = attachment.mediaUrl,
              let url = Foundation.URL(string: urlString) else { return nil }
        
        // Download the data from the URL
        do {
            let (data, _) = try await Foundation.URLSession.shared.data(from: url)
            return MediaMulti(data: data, format: attachment.format)
        } catch {
            print("Failed to download media: \(error)")
            return nil
        }
    }
}
