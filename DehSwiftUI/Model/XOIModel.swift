/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The model for an individual landmark.
 */

import SwiftUI
import CoreLocation

// get set : 讀／寫
//protocol XOIProtocol:Identifiable {
//    var id: Int{get set}
//    var name: String{get set}
//    var latitude: Double{get set}
//    var longitude: Double{get set}
//    var creatorCategory: String{get set}
//    var xoiCategory: String{get set}
//    var detail: String{get set}
//    var viewNumbers: Int{get set}
//    var mediaCategory: String{get set}
//    func getLocationCoordinate()-> CLLocationCoordinate2D
//}

import MapKit
class XOIList:Decodable{
    let results: [XOI]
    let message: String?
}
struct media_set: Codable, Hashable {
    var media_type: String
    var media_format: Int
    var media_url: String
}

class XOI: Identifiable, Decodable {
    var containedXOIs: [XOI]?
    var id: Int = 0
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var creatorCategory: String = ""
    var xoiCategory: String = "poi"
    var detail: String = ""
    var viewNumbers: Int = 0
    var mediaCategory: String = ""
    var distance: Double = 0.0
    var media_set: [media_set] = []
    var open: Bool = false
    var index: Int? = -1
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "xoiId"
        case name = "xoiTitle"
        case detail = "xoiDescription"
        case latitude
        case longitude
        case creatorCategory = "identifier"
        case media_set = "mediaSet"
        case open
        case distance
        case containedXOIs
        case index
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        detail = try container.decode(String.self, forKey: .detail)
        
        // Decode optional fields
        creatorCategory = try container.decodeIfPresent(String.self, forKey: .creatorCategory) ?? ""
        distance = try container.decodeIfPresent(Double.self, forKey: .distance) ?? 0.0
        containedXOIs = try container.decodeIfPresent([XOI].self, forKey: .containedXOIs)
        index = try container.decodeIfPresent(Int.self, forKey: .index)
        
        // Handle 'open' field that could be string or bool
        if let openString = try? container.decode(String.self, forKey: .open) {
            open = openString.lowercased() == "true"
        } else if let openBool = try? container.decode(Bool.self, forKey: .open) {
            open = openBool
        }
        
        // Flexible media_set decoding
        if let singleMediaSet = try? container.decodeIfPresent(Array<media_set>.self, forKey: .media_set) {
            media_set = singleMediaSet
        } else if let nestedMediaSet = try? container.decodeIfPresent(Array<Array<media_set>>.self, forKey: .media_set) {
            media_set = nestedMediaSet.flatMap { $0 }
        }
    }
    
    init(id: Int, name: String, latitude: Double, longitude: Double, creatorCategory: String,
         xoiCategory: String, detail: String, viewNumbers: Int, mediaCategory: String) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.creatorCategory = creatorCategory
        self.xoiCategory = xoiCategory
        self.detail = detail
        self.viewNumbers = viewNumbers
        self.mediaCategory = mediaCategory
    }
}
extension XOI:Hashable,Encodable{
    static func == (lhs: XOI, rhs: XOI) -> Bool {
        return lhs.id == rhs.id && lhs.xoiCategory == rhs.xoiCategory
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func region() -> MKCoordinateRegion{
        return MKCoordinateRegion(center: coordinate, latitudinalMeters:20000,longitudinalMeters:20000)
    }
    
    func setContainedXOI(XOIs:[XOI]){
        self.containedXOIs = XOIs
    }
}






