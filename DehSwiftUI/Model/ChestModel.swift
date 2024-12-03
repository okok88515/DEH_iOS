//
//  ChestModel.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/4/30.
//  Copyright © 2021 mmlab. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLocation

struct ChestResponse: Decodable {
    let results: [ChestModel]
    
    private enum CodingKeys: String, CodingKey {
        case results
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var chestsArrayForResults: [ChestModel] = []
        
        if let chestArray = try? container.decode([ChestModel].self, forKey: .results) {
            chestsArrayForResults = chestArray
        }
        else if let singleChest = try? container.decode(ChestModel.self, forKey: .results) {
            chestsArrayForResults = [singleChest]
        }
        
        self.results = chestsArrayForResults
    }
}

struct ChestModel: Identifiable, Decodable, Hashable {
    var id: Int
    var latitude: Double
    var longitude: Double
    var avaliableNumber: Int?
    var remainNumber: Int?
    var point: Int?
    var discoverDistance: Int?
    var questionType: Int
    var option1: String?
    var option2: String?
    var option3: String?
    var option4: String?
    var hint1: String?
    var hint2: String?
    var hint3: String?
    var hint4: String?
    var question: String
    var answer: String?
    var poiID: Int?
    var room_id_id: Int?
    var medias: [ChestMedia]?
    
    var coordinate: CLLocationCoordinate2D! {
        get {
            return CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case avaliableNumber = "num"
        case remainNumber = "remain"
        case point
        case discoverDistance = "distance"
        case questionType
        case option1
        case option2
        case option3
        case option4
        case hint1
        case hint2
        case hint3
        case hint4
        case question
        case answer
        case poiID = "PoiId"
        case room_id_id = "sessionId"
        case medias
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChestModel, rhs: ChestModel) -> Bool {
        return lhs.id == rhs.id
    }
}
