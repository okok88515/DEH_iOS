//
//  GameViewModel.swift
//  DehSwiftUI
//
//  Created by 陳家庠 on 2022/11/6.
//  Copyright © 2022 mmlab. All rights reserved.
//


// variable gameID in many places actually refers to room_id
// real room_id now is session.id = GameData.id
// real gameid is  session.gameID = GameData.game_id (game_id_id)
import Foundation
import Alamofire
import Combine

class GameViewModel:ObservableObject {
    @Published var gameList:[gameListtuple] = []
    @Published var sessionList : [SessionModel] = []
    @Published var selectedSession : SessionModel?
    @Published var selection:Int?
    @Published var chestList:[ChestModel] = []
    @Published var min:Int = 0
    @Published var sec:Int = 0
    @Published var score:Int = 0
    @Published var alertState = false
    @Published private var cancellable: AnyCancellable?
    @Published private var cancellable2: AnyCancellable?
    @Published private var cancellable3: AnyCancellable?
    @Published private var startGameCancellable: AnyCancellable?
    
    @Published private(set) var sessionScores: [Int: Int] = [:]
    
    func startGame(session: SessionModel,userID:String) {
        let url = GameStartUrl
        let parameters:[String:String] = [
            "room_id": "\(session.id)",
            "user_id": userID
        ]
        let publisher:DataResponsePublisher<String> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.startGameCancellable = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
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
    func getSessions(userID:String,groupID:Int){
        let url = getRoomList
        let parameters:[String:String] = [
            "user_id": "\(userID)",
            "coi_name": coi,
            "coi":coi,
            "language": "中文",
            "group_id":"\(groupID)",
            
            
        ]
        let publisher:DataResponsePublisher<[SessionModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
//                print(values.data?.JsonPrint())
//                print(values.debugDescription)
                if let value = values.value{
                    self.sessionList = value
                }
            })
    }
    func initial(session:SessionModel,userID:String){
        //getGameData(gameID: session.gameID)
        //getGameData(roomID: session.id)
        getGameData(session: session)
        //getChests(session: session)
        //updateScore(userID: userID, gameID: session.gameID)
        getChests(userID: userID, session: session)
        updateScore(userID: userID, session: session)
        
    }
//    func getChests(session:SessionModel){
//        let url = getChestList
//        let parameters:[String:String] = [
//            "user_id": "\(session.id)",
 //           "game_id":"\(session.gameID)",
 //       ]
//        let publisher:DataResponsePublisher<[ChestModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
//        self.cancellable = publisher
//            .sink(receiveValue: {(values) in
//                print(values.data?.JsonPrint())
//                print(values.debugDescription)
 //               if let value = values.value {
 //                   self.chestList = value
  //              }
 //               print(self.chestList)
 //           })
   // }
    
    func getChests(userID:String,session: SessionModel){
        let url = getChestList
        let parameters:[String:Any] = [
            "user_id" : userID,
            "room_id" :"\(session.id)"
        ]
        let publisher:DataResponsePublisher<[ChestModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
//                print(values.data?.JsonPrint())
                print(values.debugDescription)
                if let value = values.value {
                    self.chestList = value
                }
                print(self.chestList)
            })
    }
    
    
    //get game remaining time
    func getGameData(session: SessionModel){
        let url = getGameDataUrl
        let parameters = ["room_id": session.id]
        
        print("session info")
        print(session.id)
        print(session.gameID)
        print(session.name)
        print(session.status)
        let publisher:DataResponsePublisher<[GameData]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)

        self.cancellable3 = publisher
            .sink(receiveValue: {(values) in
                print(values.debugDescription)
                
                
                
                
                if let gameData = values.value?.first {
                    print("gamedata info")
                    print(gameData.id)
                    print(gameData.game_id)
                    print(gameData.room_id
                    )
                    session.gameID = gameData.game_id
                    print("session gameID after changing")
                    print(session.gameID)
                } else {
                    print("No Game Data available.")
                }
               //Count game remaining time
                let formatter = DateFormatter()
//              Time format in SQL
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
               
                guard let EndTime = values.value?[0].end_time
                else{
                    self.alertState = true
                    return
                }
                let currentDate = Date()
                let targetDate = formatter.date(from: String(EndTime))
                // 當前時間
                
                // Calculate second
                let difference = Int(targetDate?.timeIntervalSince(currentDate) ?? 0)
                
                // difference < 0 set 0
                print("Remain Time:",difference)
                if (difference < 0){
                    self.min = 0
                    self.sec = 0
                }
                else{
                    self.min = (difference)/60
                    self.sec = (difference) % 60
                }
//                self.min = (values.value?[0].end_time ?? 0)/60
//                self.sec = (values.value?[0].end_time ?? 0) % 60
//                print(difference)
//                self.min = (difference)/60
//                self.sec = (difference) % 60
                if self.min == 0 && self.sec == 0 {
                    self.alertState = true
                }
            })
        
    }
    
  
    
    func updateScore(userID:String, session: SessionModel) {
           let url = getUserAnswerRecord
           let parameters:[String:Any] = [ "user_id" : userID,
                                       "room_id" : session.id]
           let publisher:DataResponsePublisher<[ScoreRecord]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
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
                       self.score = sessionScore  // Update current score
                   }
               })
       }
    func updateSessionScore(sessionId: Int, points: Int) {
            sessionScores[sessionId] = (sessionScores[sessionId] ?? 0) + points
        }
}
