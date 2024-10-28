import SwiftUI
import Combine
import Alamofire

struct GameMemberPoint: View {
    @EnvironmentObject var settingStorage: SettingStorage
    @State private var cancellable: AnyCancellable?
    @State var roomID: Int = -1
    @State var gameID: Int = -1
    @State var gamePointList: [GamePointModel] = []
    
    var body: some View {
        List {
            // Original: ForEach(gamePointList) caused identity issues due to insufficient Hashable implementation
            // Changed to use indices to force unique identification of each row
            ForEach(gamePointList.indices, id: \.self) { index in
                let gamePoint = gamePointList[index]
                HStack {
                    Text(gamePoint.name)
                        .foregroundColor(Color.white)
                        .allowsTightening(true)
                        .lineLimit(1)
                        .background(Color.init(UIColor(rgba: lightGreen)))
                    Spacer()
                    // Now each point value is correctly displayed because each row has a unique identity

                    Text("Point: \(gamePoint.point)")
                        .foregroundColor(Color.white)
                }
                .listRowBackground(Color.init(UIColor(rgba: lightGreen)))
            }
        }
        .onAppear {
            getMemberPoint()
        }
    }
}

extension GameMemberPoint {
    func getMemberPoint() {
        let url = getMemberPointUrl
        let parameters: [String: String] = [
            "room_id": "\(roomID)",
            "game_id": "\(gameID)",
            "user_id": "\(settingStorage.userID)",
            "rank": "1",
        ]
        print("Fetching with parameters: \(parameters)")
        
        let publisher: DataResponsePublisher<[GamePointModel]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: { values in
                print("\n=== Network Response ===")
                print(values.debugDescription)
                
                if let value = values.value {
                    print("\n=== Raw Data ===")
                    value.forEach { point in
                        print("""
                            ID: \(point.id)
                            Name: \(point.name)
                            Point: \(point.point)
                            Answer Time: \(point.answer_time)
                            Correctness: \(point.correctness)
                            ----------------
                            """)
                    }
                    
                    let filteredList = value.filter { $0.correctness }
                    print("\n=== After Filtering (\(filteredList.count) items) ===")
                    
                    let sortedList = filteredList.sorted { $0.point > $1.point }
                    print("\n=== Final Sorted List (\(sortedList.count) items) ===")
                    sortedList.forEach { point in
                        print("""
                            ID: \(point.id)
                            Name: \(point.name)
                            Point: \(point.point)
                            Answer Time: \(point.answer_time)
                            ----------------
                            """)
                    }
                    // Added DispatchQueue.main.async to ensure UI updates happen on main thread

                    DispatchQueue.main.async {
                        self.gamePointList = sortedList
                    }
                }
            })
    }
}

struct GameMemberPoint_Previews: PreviewProvider {
    static var previews: some View {
        GameMemberPoint()
            .environmentObject(SettingStorage())
    }
}
