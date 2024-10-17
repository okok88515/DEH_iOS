//
//  GameDataModel.swift
//  DehSwiftUI
//
//  Created by 陳家庠 on 2022/1/28.
//  Copyright © 2022 mmlab. All rights reserved.
//

import Foundation

class GameData:Decodable{
    var start_time:String
    var end_time:String
    var play_time:Int
    var room_id:Int
    var id:Int
    var game_id:Int
    enum CodingKeys: String, CodingKey{
        case id = "id" //roomid = session.id = this id
        case room_id = "event_id_id" //this room_id is event_id, room_id is the above id
        case start_time = "start_time"
        case end_time = "end_time"
        case play_time = "play_time"
        case game_id = "game_id_id"
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
