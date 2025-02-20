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
            para: parameters,
            addLogs: true
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
            para: parameters,
            addLogs: true
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
    struct SessionResponse: Codable {
        let results: [SessionModel]
    }

    func getSessions(userID: String, eventId: Int) {
        let url = getRoomList
        let parameters: [String: Any] = [
            "userId": userID,
            "eventId": eventId
        ]
        print("=== getSessions API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<SessionResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters,addLogs: true)
        
        self.cancellable = publisher
            .sink(receiveValue: { [weak self] values in
                // Print raw response for debugging
                print("Raw Response:", String(data: values.data ?? Data(), encoding: .utf8) ?? "No data")
                
                if let response = values.value?.results {
                    self?.sessionList = response
                    print("Successfully decoded \(response.count) sessions")
                } else {
                    print("Failed to decode session results")
                    if let error = values.error {
                        print("Error:", error)
                    }
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
        
        let publisher: DataResponsePublisher<GameDataResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters,addLogs: true)
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
                    session.gameID = gameData.id  // gameid can be passed to chestminus API parameters
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
        
        let publisher: DataResponsePublisher<ChestResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters,addLogs: true)
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
    
    struct UserPointResponse: Decodable {
        let results: UserPoint
    }

    struct UserPoint: Decodable {
        let totalPoint: Int
        let userId: Int
        let correctAnswers: Int
    }

    func updateScore(userID: String, session: SessionModel) {
        let url = getUserPoint
        let parameters: [String: String] = [
            "userId": userID,
            "gameId": "\(session.gameID)"
        ]
        
        print("\n=== UpdateScore API Call ===")
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<UserPointResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters,addLogs: true)
        self.cancellable2 = publisher
            .sink(receiveValue: { [weak self] values in
                print("\n=== UpdateScore Response ===")
                print("Raw Response:", String(data: values.data ?? Data(), encoding: .utf8) ?? "No data")
                
                if let userPoint = values.value?.results {
                    print("Score updated to:", userPoint.totalPoint)
                    self?.score = userPoint.totalPoint
                } else {
                    print("No score data, setting to 0")
                    self?.score = 0
                }
            })
    }
    
    struct GameListResponse: Codable {
        let results: Results
        
        struct Results: Codable {
            let eventList: [EventItem]
            let groupList: [EventItem]
        }
    }
    
    // Model matching the API response structure
    struct EventItem: Codable {
        let id: Int
        let name: String
        let leaderId: Int
        let startTime: String
        let endTime: String
        
        // Convert to Group
        func toGroup() -> Group {
            return Group(
                id: id,
                name: name,
                leaderId: leaderId,
                info: "",  // Default empty info since it's not in the API response
                startTime: startTime,
                endTime: endTime
            )
        }
    }

    func getGameList(userID: String) {
        print("\n=== GetGameList API Call ===")
        print("URL:", privateGetGroupList)
        print("Parameters: userId=\(userID), coiName=\(coi)")
        
        let parameters: [String: String] = [
            "userId": userID,
            "coiName": coi,
        ]
        
        var tempList: [gameListtuple] = []
        let publisher: DataResponsePublisher<GameListResponse> = NetworkConnector().getDataPublisherDecodable(
            url: privateGetGroupList,
            para: parameters,
            addLogs: true
        )
        
        self.cancellable = publisher
            .sink(receiveValue: { [weak self] values in
                print("\n=== GetGameList Response ===")
                
                // Log HTTP Status Code
                if let statusCode = values.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                }
                
                // Log Raw Response
                if let data = values.data {
                    print("Raw Response Data:", String(data: data, encoding: .utf8) ?? "Unable to decode response data")
                    
                    // Pretty print JSON if possible
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("\nFormatted JSON Response:")
                        print(prettyString)
                    }
                }
                
                // Handle Decoding
                if let results = values.value?.results {
                    print("\nDecoding successful")
                    
                    // Log Event List
                    print("\nPublic Events:")
                    print("Count:", results.eventList.count)
                    results.eventList.forEach { event in
                        print("- Event: id=\(event.id), name=\(event.name), leaderId=\(event.leaderId)")
                        print("  startTime=\(event.startTime), endTime=\(event.endTime)")
                    }
                    
                    // Log Group List
                    print("\nPrivate Groups:")
                    print("Count:", results.groupList.count)
                    results.groupList.forEach { group in
                        print("- Group: id=\(group.id), name=\(group.name), leaderId=\(group.leaderId)")
                        print("  startTime=\(group.startTime), endTime=\(group.endTime)")
                    }
                    
                    // Process Events using correct gameListtuple initialization
                    let eventGroups = results.eventList.map { $0.toGroup() }
                    if !eventGroups.isEmpty {
                        print("\nAdding \(eventGroups.count) public events to tempList")
                        tempList.append(gameListtuple("public".localized, eventGroups))
                    }
                    
                    // Process Groups using correct gameListtuple initialization
                    let privateGroups = results.groupList.map { $0.toGroup() }
                    if !privateGroups.isEmpty {
                        print("\nAdding \(privateGroups.count) private groups to tempList")
                        tempList.append(gameListtuple("private".localized, privateGroups))
                    }
                    
                    print("\nFinal tempList count:", tempList.count)
                    self?.gameList = tempList
                    print("GameList updated successfully")
                    
                } else {
                    print("\nDecoding Failed")
                    
                    // Log any errors
                    if let error = values.error {
                        print("Error:", error)
                        
                        // Detailed error logging for DecodingError
                        if let decodingError = error.asAFError?.underlyingError as? DecodingError {
                            print("\nDecoding Error Details:")
                            switch decodingError {
                            case .dataCorrupted(let context):
                                print("Data Corrupted:")
                                print("Debug Description:", context.debugDescription)
                                print("Coding Path:", context.codingPath)
                                
                            case .keyNotFound(let key, let context):
                                print("Key Not Found:")
                                print("Missing Key:", key)
                                print("Debug Description:", context.debugDescription)
                                print("Coding Path:", context.codingPath)
                                
                            case .typeMismatch(let type, let context):
                                print("Type Mismatch:")
                                print("Expected Type:", type)
                                print("Debug Description:", context.debugDescription)
                                print("Coding Path:", context.codingPath)
                                
                            case .valueNotFound(let type, let context):
                                print("Value Not Found:")
                                print("Expected Type:", type)
                                print("Debug Description:", context.debugDescription)
                                print("Coding Path:", context.codingPath)
                                
                            @unknown default:
                                print("Unknown Decoding Error:", decodingError)
                            }
                        }
                    }
                }
                
                print("\n=== GetGameList Completed ===")
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
