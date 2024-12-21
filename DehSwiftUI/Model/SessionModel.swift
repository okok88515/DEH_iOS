//
//  SessionModel.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/4/28.
//  Copyright © 2021 mmlab. All rights reserved.
//

import Foundation
import SwiftUI

class SessionModel: Codable, Hashable, Identifiable {
    var id: Int
    var name: String
    var gameID: Int = -1
    var status: String
    var autoStart: Bool    // Changed back to Bool since backend sends false/true
    var isPlaying: Int     // Keep as Int since backend sends 0/1
    var startTime: String?
    var endTime: String?
    
    init(id: Int, name: String, gameID: Int = -1, status: String, autoStart: Bool = false, isPlaying: Int = 0, startTime: String = "", endTime: String = "") {
        self.id = id
        self.name = name
        self.gameID = gameID
        self.status = status
        self.autoStart = autoStart
        self.isPlaying = isPlaying
        self.startTime = startTime
        self.endTime = endTime
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "sessionName"
        case status
        case autoStart
        case isPlaying
        case startTime
        case endTime
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool {
        return lhs.id == rhs.id
    }
}
