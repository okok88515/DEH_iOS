import SwiftUI
import CoreLocation
import MapKit

// MARK: - Media Set Struct
struct MediaSet: Codable, Hashable {
    var mediaType: String
    var mediaFormat: Int
    var mediaUrl: String
    
    init(mediaType: String, mediaFormat: Int, mediaUrl: String) {
        self.mediaType = mediaType
        self.mediaFormat = mediaFormat
        self.mediaUrl = mediaUrl
    }
}

// MARK: - XOI List Wrapper
struct XOIList: Codable {
    let results: [XOI]
    let message: String?
    
    init(results: [XOI], message: String? = nil) {
        self.results = results
        self.message = message
    }
}

// MARK: - XOI Model
class XOI: Identifiable, Codable, Hashable {
    var containedXOIs: [XOI]?
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let creatorCategory: String
    var xoiCategory: String
    let detail: String
    var viewNumbers: Int
    var mediaCategory: String
    let distance: Double? // Made optional to handle missing values
    var mediaSet: [MediaSet] = []
    let open: Bool
    let index: Int?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "xoiId"
        case name = "xoiTitle"
        case detail = "xoiDescription"
        case latitude
        case longitude
        case creatorCategory = "identifier"
        case mediaSet
        case open
        case distance
        case containedXOIs
        case index
        case xoiCategory
        case viewNumbers
        case mediaCategory
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        detail = try container.decode(String.self, forKey: .detail)
        
        // Decode optional fields with defaults
        creatorCategory = try container.decodeIfPresent(String.self, forKey: .creatorCategory) ?? ""
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        containedXOIs = try container.decodeIfPresent([XOI].self, forKey: .containedXOIs)
        index = try container.decodeIfPresent(Int.self, forKey: .index)
        xoiCategory = try container.decodeIfPresent(String.self, forKey: .xoiCategory) ?? "poi"
        viewNumbers = try container.decodeIfPresent(Int.self, forKey: .viewNumbers) ?? 0
        mediaCategory = try container.decodeIfPresent(String.self, forKey: .mediaCategory) ?? "none"
        
        // Handle 'open' field that could be string or bool
        if let openString = try? container.decode(String.self, forKey: .open) {
            open = openString.lowercased() == "true"
            print("[DEBUG] Decoded 'open' as string: \(openString) -> \(open)")
        } else if let openBool = try? container.decode(Bool.self, forKey: .open) {
            open = openBool
            print("[DEBUG] Decoded 'open' as bool: \(open)")
        } else {
            open = false // Default value
            print("[DEBUG] Could not decode 'open', using default: false")
        }
        
        // Decode mediaSet
        do {
            mediaSet = try container.decodeIfPresent([MediaSet].self, forKey: .mediaSet) ?? []
            print("[DEBUG] Decoded \(mediaSet.count) media items for XOI \(id)")
            mediaSet.forEach { media in
                print("[DEBUG] - Media: type=\(media.mediaType), format=\(media.mediaFormat), url=\(media.mediaUrl)")
            }
        } catch {
            mediaSet = []
            print("[DEBUG] Failed to decode mediaSet for XOI \(id): \(error.localizedDescription)")
        }
        
        // Set mediaCategory based on first media item (if not already set)
        if mediaCategory == "none", let firstMedia = mediaSet.first {
            switch firstMedia.mediaFormat {
            case 1: mediaCategory = "image"
            case 2: mediaCategory = "audio"
            case 4: mediaCategory = "video"
            case 8: mediaCategory = "commentary"
            default: mediaCategory = "none"
            }
        }
    }
    
    // Custom encoder to handle optional and mutable properties
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(detail, forKey: .detail)
        try container.encode(creatorCategory, forKey: .creatorCategory)
        try container.encode(open, forKey: .open)
        try container.encode(xoiCategory, forKey: .xoiCategory)
        try container.encode(viewNumbers, forKey: .viewNumbers)
        try container.encode(mediaCategory, forKey: .mediaCategory)
        try container.encode(mediaSet, forKey: .mediaSet)
        
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(containedXOIs, forKey: .containedXOIs)
        try container.encodeIfPresent(index, forKey: .index)
    }
    
    // Manual initializer for testing
    init(id: Int, name: String, latitude: Double, longitude: Double, creatorCategory: String,
         xoiCategory: String = "poi", detail: String, viewNumbers: Int = 0, mediaCategory: String = "none",
         distance: Double? = 0.0, mediaSet: [MediaSet] = [], open: Bool = true, index: Int? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.creatorCategory = creatorCategory
        self.xoiCategory = xoiCategory
        self.detail = detail
        self.viewNumbers = viewNumbers
        self.mediaCategory = mediaCategory
        self.distance = distance
        self.mediaSet = mediaSet
        self.open = open
        self.index = index
    }
    
    // Hashable implementation
    static func == (lhs: XOI, rhs: XOI) -> Bool {
        return lhs.id == rhs.id && lhs.xoiCategory == rhs.xoiCategory
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Additional utility methods
    func region() -> MKCoordinateRegion {
        return MKCoordinateRegion(center: coordinate, latitudinalMeters: 20000, longitudinalMeters: 20000)
    }
    
    func setContainedXOI(XOIs: [XOI]) {
        self.containedXOIs = XOIs
    }
}
