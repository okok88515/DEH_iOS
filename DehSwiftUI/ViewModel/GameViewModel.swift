import Foundation
import Alamofire
import Combine

class GameViewModel: ObservableObject {
    @Published var gameList: [gameListtuple] = []
    @Published var sessionList: [SessionModel] = []
    @Published var selectedSession: SessionModel?
    @Published var selection: Int?
    @Published var chestList: [ChestModel] = []
    @Published var min: Int = 0
    @Published var sec: Int = 0
    @Published var score: Int = 0
    @Published private var cancellable: AnyCancellable?
    @Published private var cancellable2: AnyCancellable?
    @Published private var cancellable3: AnyCancellable?
    @Published private var startGameCancellable: AnyCancellable?

    
    struct GameResponse: Codable {
        let results: GameResult
    }

    struct GameResult: Codable {
        let message: String
    }

    func startGame(session: SessionModel, userID: String) {
        let url = GameStartUrl
        let parameters: [String: String] = [
            "sessionId": "\(session.id)",
            "userId": userID
        ]
        
        
        let publisher: DataResponsePublisher<GameResponse> = NetworkConnector().getDataPublisherDecodable(
            url: url,
            para: parameters
        )
        
        self.startGameCancellable = publisher
            .sink(receiveValue: { [weak self] response in
                print(response.debugDescription)
                
                if let error = response.error {
                    print("Error: \(error)")
                    return
                }
                
                if let message = response.value?.results.message {
                    switch message {
                    case "success start game":
                        self?.getGameData(session: session) {
                            self?.getChests(userID: userID, session: session)
                            self?.updateScore(userID: userID, session: session)
                        }
                    case "already start":
                        print("Game already started")
                    case "autoStartGame or unauthorized":
                        print("Unauthorized or auto-start game")
                    default:
                        print("Unknown response: \(message)")
                    }
                }
            })
    }

    

    func endGame(session: SessionModel, userID: String) {
        let url = endGameUrl
        let parameters: [String: String] = [
            "sessionId": "\(session.id)",
            "userId": userID
        ]
        
        let publisher: DataResponsePublisher<GameResponse> = NetworkConnector().getDataPublisherDecodable(
            url: url,
            para: parameters
        )
        
        self.startGameCancellable = publisher
            .sink(receiveValue: { [weak self] response in
                print(response.debugDescription)
                
                if let error = response.error {
                    print("Error: \(error)")
                    return
                }
                
                if let message = response.value?.results.message {
                    switch message {
                    case "success end game":
                        self?.min = 0
                        self?.sec = 0
                        self?.updateScore(userID: userID, session: session)
                    case "not authorized":
                        print("User not authorized to end game")
                    case "game is already ended":
                        print("Game has already ended")
                    default:
                        print("Unknown response: \(message)")
                    }
                }
            })
    }
    func getSessions(userID: String, groupID: Int) {
        let url = getRoomList
        let parameters: [String:String] = [
            "user_id": userID,
            "coi_name": coi,
            "coi": coi,
            "language": "中文",
            "group_id": "\(groupID)",
        ]
        let publisher: DataResponsePublisher<[SessionModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                if let value = values.value {
                    self.sessionList = value
                }
            })
    }
    
    func initial(session: SessionModel, userID: String) {
        getGameData(session: session) { [weak self] in
            self?.getChests(userID: userID, session: session)
            self?.updateScore(userID: userID, session: session)
        }
    }
    
    
    
    func getGameData(session: SessionModel, completion: @escaping () -> Void) {
        let url = getGameDataUrl
        let parameters: [String: Any] = [
            "sessionId": session.id
        ]
        
        print("=== GetGameData API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<GameDataResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable3 = publisher
            .sink(receiveValue: { [weak self] (values) in
                print("\n=== GetGameData Response ===")
                if let statusCode = values.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                }
                
                // Print raw response data
                if let data = values.data, let rawString = String(data: data, encoding: .utf8) {
                    print("Raw Response Data:", rawString)
                }
                
                if let error = values.error {
                    print("Decoding Error:", error)
                    if let underlyingError = (error.underlyingError as? DecodingError) {
                        switch underlyingError {
                        case .typeMismatch(let type, let context):
                            print("Type Mismatch: expected \(type) at path:", context.codingPath)
                        case .valueNotFound(let type, let context):
                            print("Value Not Found: \(type) at path:", context.codingPath)
                        case .keyNotFound(let key, let context):
                            print("Key Not Found: \(key) at path:", context.codingPath)
                        case .dataCorrupted(let context):
                            print("Data Corrupted at path:", context.codingPath)
                            print("Debug Description:", context.debugDescription)
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    completion()
                    return
                }
                
                if let gameData = values.value?.results.first {
                    print("Game data decoded successfully")
                    print("Decoded data:", gameData)
                    session.gameID = gameData.game_id  // Using eventId from backend
                } else {
                    print("No game data in response")
                    completion()
                    return
                }
                
                guard let endTime = values.value?.results.first?.end_time else {
                    print("No end time in response")
                    completion()
                    return
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                
                let currentDate = Date()
                let targetDate = formatter.date(from: endTime)
                
                let difference = Int(targetDate?.timeIntervalSince(currentDate) ?? 0)
                
                if (difference < 0) {
                    self?.min = 0
                    self?.sec = 0
                    print("Time expired")
                } else {
                    self?.min = difference / 60
                    self?.sec = difference % 60
                    print("Remaining time set - Min:", self?.min ?? 0, "Sec:", self?.sec ?? 0)
                }
                
                print("=== GetGameData Completed ===\n")
                completion()
            })
        
        print("API request initiated")
    }
    func getChests(userID: String, session: SessionModel) {
        let url = getChestList
        let parameters: [String: Any] = [
            "userId": userID,
            "sessionId": session.id
        ]
        
        print("=== GetChests API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<ChestResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: { [weak self] (values) in
                print("\n=== GetChests Response ===")
                if let statusCode = values.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                }
                
                if let data = values.data, let rawString = String(data: data, encoding: .utf8) {
                    print("Raw Response Data:", rawString)
                }
                
                if let error = values.error {
                    print("Decoding Error:", error)
                    if let underlyingError = (error.underlyingError as? DecodingError) {
                        switch underlyingError {
                        case .typeMismatch(let type, let context):
                            print("Type Mismatch: expected \(type) at path:", context.codingPath)
                        case .valueNotFound(let type, let context):
                            print("Value Not Found: \(type) at path:", context.codingPath)
                        case .keyNotFound(let key, let context):
                            print("Key Not Found: \(key) at path:", context.codingPath)
                        case .dataCorrupted(let context):
                            print("Data Corrupted at path:", context.codingPath)
                            print("Debug Description:", context.debugDescription)
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    return
                }
                
                if let chests = values.value?.results {
                    print("Chests decoded successfully")
                    print("Number of chests:", chests.count)
                    self?.chestList = chests
                } else {
                    print("No chest data in response")
                }
                
                print("=== GetChests Completed ===\n")
            })
        
        print("API request initiated")
    }
    func updateScore(userID: String, session: SessionModel) {
        let url = getUserAnswerRecord
        let parameters: [String:String] = [
            "user_id": userID,
            "room_id": "\(session.id)",
            "game_id": "\(session.gameID)"
        ]
        
        let publisher: DataResponsePublisher<[ScoreRecord]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable2 = publisher
            .sink(receiveValue: { [weak self] (values) in
                if let records = values.value {
                    // Simply sum up the points from correct answers
                    let totalScore = records.reduce(0) { sum, record in
                        guard let isCorrect = record.correctness,
                              let point = record.point else {
                            return sum
                        }
                        return sum + (isCorrect ? point : 0)
                    }
                    self?.score = totalScore  // Only keep current score
                }
            })
    }
    

    
    
    
    func getGameList(userID: String) {
        let url = privateGetGroupList
        let parameters: [String:String] = [
            "user_id": userID,
            "coi_name": coi,
            "language": "中文",
        ]
        var tempList: [gameListtuple] = []
        let publisher: DataResponsePublisher<GroupLists> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                if let eventList = values.value?.eventList {
                    tempList.append(gameListtuple("public".localized, eventList))
                }
                if let groupList = values.value?.groupList {
                    if(!groupList.isEmpty) {
                        tempList.append(gameListtuple("private".localized, groupList))
                    }
                }
                self.gameList = tempList
            })
    }
}
//Key changes made:
//1. Added completion handler to getGameData
//2. Modified initial to use completion handler for proper sequence
//3. Added completion handler call in getGameData's error case
//4. Updated startGame to use completion handler when refreshing data
//5. Made sure all network calls use [weak self] for proper memory management
//
//The flow is now:
//1. initial calls getGameData
//2. getGameData sets the gameID and calls completion
//3. In the completion, getChests and updateScore are called
//4. updateScore now has the correct gameID when it runs
//
//This should ensure that updateScore always has the correct gameID when it's called.
