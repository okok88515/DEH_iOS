import Foundation
import CoreLocation

// ChestMedia structure to match backend response
struct ChestMedia: Codable {
    let mediaUrl: String
    let mediaFormat: Int
    
    var url: URL? {
        return URL(string: mediaUrl)
    }
    
    var mediaType: format {
        return format(rawValue: mediaFormat) ?? .Default
    }
    
    enum CodingKeys: String, CodingKey {
        case mediaUrl, mediaFormat
        case ATT_url, ATT_format
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try first format (from chest endpoint)
        if let url = try? container.decode(String.self, forKey: .mediaUrl) {
            self.mediaUrl = url
            self.mediaFormat = try container.decode(Int.self, forKey: .mediaFormat)
            print("Decoded using mediaUrl format")
            return
        }
        
        // Try second format (from media endpoint)
        if let url = try? container.decode(String.self, forKey: .ATT_url) {
            self.mediaUrl = url
            let format = try container.decode(String.self, forKey: .ATT_format)
            // Convert string format to int
            switch format.lowercased() {
            case "image": self.mediaFormat = 1
            case "audio", "voice": self.mediaFormat = 2
            case "video": self.mediaFormat = 4
            case "commentary": self.mediaFormat = 8
            default: self.mediaFormat = 0
            }
            print("Decoded using ATT_url format")
            return
        }
        
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Could not decode media using either format"
            )
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mediaUrl, forKey: .mediaUrl)
        try container.encode(mediaFormat, forKey: .mediaFormat)
    }
}
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
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude)
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
    
    func loadMediaContents(completion: @escaping ([MediaMulti]) -> Void) {
        print("Starting loadMediaContents")
        guard let medias = self.medias else {
            print("No medias array found")
            completion([])
            return
        }
        
        print("Found \(medias.count) media items")
        print("Media items:", medias)
        
        let group = DispatchGroup()
        var mediaContents: [MediaMulti] = []
        
        for media in medias {
            group.enter()
            
            guard let url = media.url else {
                print("Invalid media URL:", media.mediaUrl)
                group.leave()
                continue
            }
            
            print("Loading media from URL:", url)
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading media: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Media response status code:", httpResponse.statusCode)
                }
                
                if let data = data {
                    print("Successfully loaded media data of size:", data.count)
                    let mediaContent = MediaMulti(data: data, format: media.mediaType)
                    DispatchQueue.main.async {
                        mediaContents.append(mediaContent)
                        print("Added media content to array. Current count:", mediaContents.count)
                    }
                } else {
                    print("No data received for media")
                }
            }.resume()
        }
        
        group.notify(queue: .main) {
            print("All media loading complete. Final count:", mediaContents.count)
            completion(mediaContents)
        }
    }
}
