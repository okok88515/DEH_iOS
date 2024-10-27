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
    
    @Published private(set) var sessionScores: [Int: Int] = [:]
    
    func startGame(session: SessionModel, userID: String) {
        let url = GameStartUrl
        let parameters: [String:String] = [
            "room_id": "\(session.id)",
            "user_id": userID
        ]
        let publisher: DataResponsePublisher<String> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.startGameCancellable = publisher
            .sink(receiveValue: { [weak self] (values) in
                print(values.debugDescription)
                // After starting the game, refresh game data to get new timer
                self?.getGameData(session: session)
                self?.getChests(userID: userID, session: session)
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
        getGameData(session: session)
        getChests(userID: userID, session: session)
        updateScore(userID: userID, session: session)
    }
    
    func getChests(userID: String, session: SessionModel) {
        let url = getChestList
        let parameters: [String:Any] = [
            "user_id": userID,
            "room_id": "\(session.id)"
        ]
        let publisher: DataResponsePublisher<[ChestModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
                if let value = values.value {
                    self.chestList = value
                }
                print(self.chestList)
            })
    }
    
    func getGameData(session: SessionModel) {
        let url = getGameDataUrl
        let parameters = ["room_id": session.id]
        
        print("session info")
        print(session.id)
        print(session.gameID)
        print(session.name)
        print(session.status)
        
        let publisher: DataResponsePublisher<[GameData]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable3 = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
                
                if let gameData = values.value?.first {
                    print("gamedata info")
                    print(gameData.id)
                    print(gameData.game_id)
                    print(gameData.room_id)
                    session.gameID = gameData.game_id
                    print("session gameID after changing")
                    print(session.gameID)
                } else {
                    print("No Game Data available.")
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
               
                guard let EndTime = values.value?[0].end_time
                else {
                    return
                }
                
                let currentDate = Date()
                let targetDate = formatter.date(from: String(EndTime))
                
                let difference = Int(targetDate?.timeIntervalSince(currentDate) ?? 0)
                
                print("Remain Time:", difference)
                if (difference < 0) {
                    self.min = 0
                    self.sec = 0
                } else {
                    self.min = (difference)/60
                    self.sec = (difference) % 60
                }
            })
    }
    
    func updateScore(userID: String, session: SessionModel) {
        let url = getUserAnswerRecord
        let parameters: [String:Any] = [
            "user_id": userID,
            "room_id": session.id
        ]
        let publisher: DataResponsePublisher<[ScoreRecord]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable2 = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
                if let records = values.value {
                    var sessionScore = 0
                    for record in records {
                        print(record.chest_id)
                        self.chestList = self.chestList.filter({$0.id != record.chest_id})
                        if record.correctness == 1 {
                            sessionScore += record.point
                        }
                        print(self.chestList)
                    }
                    self.sessionScores[session.id] = sessionScore
                    self.score = sessionScore
                }
            })
    }
    
    func updateSessionScore(sessionId: Int, points: Int) {
        sessionScores[sessionId] = (sessionScores[sessionId] ?? 0) + points
    }
    
    func endGame(session: SessionModel, userID: String) {
        let url = endGameUrl
        let parameters: [String:String] = [
            "room_id": "\(session.id)",
            "user_id": userID
        ]
        let publisher: DataResponsePublisher<String> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.startGameCancellable = publisher
            .sink(receiveValue: { [weak self] (values) in
                print(values.debugDescription)
                self?.min = 0
                self?.sec = 0
                self?.sessionScores[session.id] = 0
                self?.score = 0
            })
    }
    func getGameList(userID:String) {
            let url = privateGetGroupList
            let parameters:[String:String] = [
                "user_id": "\(userID)",
                "coi_name": coi,
                "language": "中文",
            ]
            var tempList : [gameListtuple] = []
            let publisher:DataResponsePublisher<GroupLists> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
            self.cancellable = publisher
                .sink(receiveValue: {(values) in
    //                print(values.debugDescription)
                    if let eventList = values.value?.eventList {
                        tempList.append(gameListtuple("public".localized,eventList))
                    }
                    if let groupList = values.value?.groupList{
                        if(!groupList.isEmpty){
                            tempList.append(gameListtuple("private".localized,groupList))
                        }}
                    self.gameList = tempList
                })
        }
        
}
