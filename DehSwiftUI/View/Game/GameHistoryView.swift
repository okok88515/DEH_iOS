// GameHistoryView.swift
import SwiftUI
import Combine
import Alamofire

struct GameHistoryView: View {
    @State private var showingSheet = false
    @State var selection: Int? = nil
    var session: SessionModel
    @State var gameHistoryList: [GameHistoryModel] = []
    @EnvironmentObject var settingStorage: SettingStorage
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        List {
            ForEach(gameHistoryList, id: \.id) { gameHistory in
                NavigationLink(
                    destination: GameMemberPoint(
                        roomID: self.session.id,
                        gameID: gameHistory.id
                    ),
                    label: {
                        Text(gameHistory.name ?? "error")
                            .foregroundColor(Color.white)
                            .allowsTightening(true)
                            .lineLimit(1)
                            .background(Color.init(UIColor(rgba: lightGreen)))
                    })
                    .listRowBackground(Color.init(UIColor(rgba: lightGreen)))
            }
        }
        .onAppear() {
            getHistory()
        }
    }
}

extension GameHistoryView {
    func getHistory() {
        let url = getGameHistory
        let parameters: [String: String] = [
            "sessionId": "\(session.id)",
            "userId": "\(settingStorage.userID)"
        ]
        print("=== getHistory API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<GameHistoryResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print(values.debugDescription)
                print(Date())
                if let value = values.value {
                    self.gameHistoryList = value.results
                } else if let error = values.error {
                    print("Error decoding: \(error)")
                }
            })
    }
}

struct GameHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        GameHistoryView(
            session: testSession,
            gameHistoryList: [
                GameHistoryModel(id: 1, startTime: "2024-10-24T10:00:00Z", state: 2),
                GameHistoryModel(id: 2, startTime: "2024-10-24T12:00:00Z", state: 0)
            ]
        )
    }
}
