//
//  GameDataModel.swift
//  DehSwiftUI
//
//  Created by 陳家庠 on 2022/1/28.
//  Copyright © 2022 mmlab. All rights reserved.
//

import Foundation

struct GameDataResponse: Decodable {
    let results: [GameData]
    
    private enum CodingKeys: String, CodingKey {
        case results
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var gamesArrayForResults: [GameData] = []
        
        // Try to decode as array
        if let gameDataArray = try? container.decode([GameData].self, forKey: .results) {
            gamesArrayForResults = gameDataArray
        }
        // If array decoding fails, try to decode as single object
        else if let singleGame = try? container.decode(GameData.self, forKey: .results) {
            gamesArrayForResults = [singleGame]
        }
        
        self.results = gamesArrayForResults
    }
}

class GameData: Decodable {
    var start_time: String
    var end_time: String
    var play_time: Int
    var room_id: Int
    var id: Int
    var game_id: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "id"               // From the LEFT JOIN EventHistory table
        case room_id = "sessionId"   // This is the session ID from EventSetting
        case start_time = "startTime"
        case end_time = "endTime"
        case play_time = "playTime"
        case game_id = "eventId"     // This maps to event_id_id in the new structure
    }
    
    init() {
        start_time = ""
        end_time = ""
        play_time = 0
        room_id = -1
        id = -1
        game_id = -1
    }
}

