import SwiftUI
import Combine
import Alamofire

struct GameMemberPoint: View {
    @EnvironmentObject var settingStorage: SettingStorage
    @State private var cancellable: AnyCancellable?
    @State var roomID: Int = -1
    @State var gameID: Int = -1
    @State var gamePointList: [GamePointModel] = []
    @State var totalScore: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("總分：\(getTotalScore())")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.init(UIColor(rgba: lightGreen)))
            
            List {
                ForEach(gamePointList.indices, id: \.self) { index in
                    let gamePoint = gamePointList[index]
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("題目")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(gamePoint.question ?? "無")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        .padding(.bottom, 8)
                        
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("你的答案")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(gamePoint.answer ?? "無")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("得分")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(getPointScore(gamePoint))")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        HStack {
                            Text("正確性：")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(gamePoint.correctness ? "正確" : "錯誤")
                                .foregroundColor(gamePoint.correctness ? Color.yellow.opacity(0.85) : .red)
                                .bold()
                        }
                        
                        if let att = gamePoint.questionATT?.first {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("附件")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(att.mediaUrl ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                    .padding(.leading, 10)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.init(UIColor(rgba: lightGreen)).opacity(0.9))
                    .cornerRadius(8)
                    .listRowBackground(Color.clear)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            getMemberPoint()
        }
    }
    
    func getPointScore(_ gamePoint: GamePointModel) -> Int {
        return gamePoint.correctness ? (gamePoint.point ?? 0) : 0
    }
    
    func getTotalScore() -> Int {
        return gamePointList.reduce(0) { total, point in
            total + (point.correctness ? (point.point ?? 0) : 0)
        }
    }
}
//這應該叫分數紀錄
extension GameMemberPoint {
    func getMemberPoint() {
        let url = getUserAnswerRecord
        let parameters: [String: String] = [
            "userId": "\(settingStorage.userID)",
            "gameId": "\(gameID)"
        ]
        
        let publisher: DataResponsePublisher<GamePointResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { values in
                if let records = values.value?.results {
                    let total = records.reduce(0) { $0 + ($1.point ?? 0) }
                    
                    DispatchQueue.main.async {
                        self.gamePointList = records
                        self.totalScore = total
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
