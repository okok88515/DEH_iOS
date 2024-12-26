//
//  GameHistoryModel.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/4/29.
//  Copyright © 2021 mmlab. All rights reserved.
//
import Foundation
import SwiftUI

struct GameHistoryResponse: Decodable {
    let results: [GameHistoryModel]
}

class GameHistoryModel: Decodable, Hashable, Identifiable {
    var id: Int
    var startTime: String
    var state: Int?
    var name: String?
    let isoFormatter = ISO8601DateFormatter()
    
    init(id: Int, startTime: String, state: Int? = nil) {
        self.id = id
        self.startTime = startTime
        self.state = state
        
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: self.startTime)?.addingTimeInterval(-8 * 3600) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm E, d MMM y"
            self.name = formatter.string(from: date)
        }
        else {
            self.name = "no date"
        }
    }
    
    required init(from decoder: Decoder) {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            startTime = try container.decode(String.self, forKey: .startTime)
            state = try container.decodeIfPresent(Int.self, forKey: .state)
            
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: startTime)?.addingTimeInterval(-8 * 3600) {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm E, d MMM y"
                name = formatter.string(from: date)
            }
            else {
                name = "no date"
            }
        }
        catch {
            print("Decoding error: \(error)")
            id = -1
            startTime = ""
            state = nil
            name = "decode error"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "startTime"
        case state
        case name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GameHistoryModel, rhs: GameHistoryModel) -> Bool {
        return lhs.id == rhs.id
    }
}

class gameListtuple : Identifiable, Hashable{
    var id = UUID()
    var sectionName:String = ""
    var groupList:[Group] = []
    init(_ sectionName:String, _ groupList:[Group]) {
        self.sectionName = sectionName
        self.groupList = groupList
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: gameListtuple, rhs: gameListtuple) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ScoreResponse: Decodable {
    let results: [ScoreRecord]
}

class ScoreRecord: Decodable {
    var answer: String?
    var chest_id: Int?
    var correctness: Bool?
    var option1: String?
    var option2: String?
    var option3: String?
    var option4: String?
    var point: Int?
    var question: String?
    var question_type: Int?
    var recordId: Int?
    var questionATT: [MediaAttachment]?
    var recordATT: [MediaAttachment]?
    
    enum CodingKeys: String, CodingKey {
        case answer
        case chest_id = "chestId"  // Map to new API's chestId
        case correctness
        case option1
        case option2
        case option3
        case option4
        case point
        case question
        case question_type = "questionType"  // Map to new API's questionType
        case recordId
        case questionATT
        case recordATT
    }
}

struct MediaAttachment: Decodable {
    var mediaUrl: String?
    var mediaFormat: Int?
}
