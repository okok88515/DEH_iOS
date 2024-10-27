import SwiftUI
import MapKit
import Combine
import Alamofire

struct GameMap: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage: SettingStorage
    @State var gameVM: GameViewModel
    @State var group: Group
    @State var session: SessionModel
    
    // Timer setup
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UI States
    @State private var startGameCancellable: AnyCancellable?
    @State private var showEndGameAlert = false
    
    // Computed property to check if game is in progress
    private var isGameInProgress: Bool {
        return gameVM.min > 0 || gameVM.sec > 0
    }
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $locationManager.coordinateRegion,
                annotationItems: gameVM.chestList) { chest in
                MapAnnotation(
                    coordinate: chest.coordinate,
                    anchorPoint: CGPoint(x: 0.5, y: 0.5)
                ) {
                    NavigationLink(destination: ChestDetailView(gameVM: gameVM,
                                                              chest: chest,
                                                              session: session)) {
                        if chest.discoverDistance != nil {
                            Image("chest")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .hidden(locationManager.getDistanceFromCurrentPlace(coordinate: chest.coordinate) >
                                      Double(chest.discoverDistance ?? Int.max))
                        } else {
                            Image("chest")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                gameVM.initial(session: session, userID: settingStorage.userID)
                print(gameVM.chestList)
            }
            
            // End Game Button (Show if game is in progress)
            if isGameInProgress {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            gameVM.endGame(session: session, userID: settingStorage.userID)
                            showEndGameAlert = true
                        } label: {
                            Text("End")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.red)
                                        .shadow(radius: 5)
                                )
                        }
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                    Spacer()
                }
            }
            
            // Timer and Controls Overlay
            VStack {
                // Timer Display
                Text("\(gameVM.min):\(String(format: "%02d", gameVM.sec))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.8))
                            .shadow(radius: 5)
                    )
                    .padding(.top, 50)
                    .onReceive(timer) { _ in
                        if isGameInProgress {
                            updateTimer()
                        }
                    }
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 15) {
                    // Start Game Button (Only show if game is not in progress)
                    if !isGameInProgress {
                        Button {
                            gameVM.startGame(session: session, userID: settingStorage.userID)
                        } label: {
                            Text("Start Game")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.yellow)
                                        .shadow(radius: 5)
                                )
                        }
                    }
                    
                    // Score Display
                    Text("Score：\(gameVM.sessionScores[session.id] ?? 0)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.green)
                                .shadow(radius: 5)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .alert("End Game", isPresented: $showEndGameAlert) {
            Button("Cancel", role: .cancel) { }
            Button("OK", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to end the game?".localized)
        }
    }
    
    // Timer update logic
    private func updateTimer() {
        if gameVM.sec > 0 {
            gameVM.sec -= 1
        } else if gameVM.min > 0 {
            gameVM.min -= 1
            gameVM.sec = 59
        }
    }
}

// Preview Provider
struct GameMap_Previews: PreviewProvider {
    static var previews: some View {
        GameMap(gameVM: GameViewModel(),
                group: testGroup,
                session: testSession)
            .environmentObject(SettingStorage())
    }
}
