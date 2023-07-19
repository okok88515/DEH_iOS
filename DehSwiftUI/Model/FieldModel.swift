//
//  FieldModel.swift
//  DehSwiftUI
//
//  Created by 廖偉博 on 2022/12/25.
//  Copyright © 2022 mmlab. All rights reserved.
//

import Foundation
import SwiftUI
import Alamofire



class Field:Identifiable,Decodable,Hashable {
    var id:Int
    var name:String
    var info:String?
    
    enum CodingKeys: String, CodingKey{
        case id
        case name
        case info
    }
    init(id:Int,name:String, info:String) {
        self.id = id
        self.name = name
        self.info = info
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: Field, rhs: Field) -> Bool {
        return lhs.id == rhs.id
    }
}

class FieldName:Decodable,Identifiable {
    var name:String
    init(name:String) {
        self.name = name
    }
    
    enum CodingKeys:String, CodingKey {
        case name = "field_name"
    }
}

