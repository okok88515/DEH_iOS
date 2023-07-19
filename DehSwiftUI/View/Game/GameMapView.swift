//
//  GameMap.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/4/30.
//  Copyright © 2021 mmlab. All rights reserved.
//

import SwiftUI
import MapKit
import Combine
import Alamofire
struct GameMap: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage:SettingStorage
    @State var gameVM:GameViewModel
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var group:Group
    @State var session:SessionModel
    @State private var startGameCancellable: AnyCancellable?

//    @State var selection: Int? = nil
    @State var alertState = false
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.coordinateRegion, annotationItems: gameVM.chestList){
                chest in
                MapAnnotation(
                    coordinate: chest.coordinate,
                    anchorPoint: CGPoint(x: 0.5, y: 0.5)
                ){
                    NavigationLink(destination: { ChestDetailView(gameVM:gameVM, chest: chest,session:session)}) {
                        if chest.discoverDistance != nil {
                            Image("chest")
                                .hidden(locationManager.getDistanceFromCurrentPlace(coordinate: chest.coordinate) > Double(chest.discoverDistance ?? Int(INT_MAX)))
                        }
                        else {
                            Image("chest")
                        }
                        
                    }
                }
            }
            .onAppear(){
                gameVM.initial(session: session, userID: settingStorage.userID)
//                locationManager.startUpdate()
                print(gameVM.chestList)
                
            }
//            .onDisappear(){
//                locationManager.stopUpdate()
//            }
            .alert(isPresented: $gameVM.alertState) { () -> Alert in
                return Alert(title: Text("game does not start".localized),
                             dismissButton:.default(Text("OK".localized), action: {
//                    self.presentationMode.wrappedValue.dismiss()
                }))
            }
            VStack {
                Text("\(gameVM.min):\(gameVM.sec)")
                    .font(.largeTitle)
                    .background(Color.gray)
                    .onReceive(timer){ _ in
                        if gameVM.sec > 0 {
                            gameVM.sec -= 1
                        }
                        else {
                            if gameVM.min != 0 {
                                gameVM.sec = 60
                                gameVM.min -= 1
                            }
                        }
                    }
                Spacer()
                VStack(alignment: .leading,spacing: 10){
                    Button {
                        gameVM.startGame(session: session)
                        
                    } label: {
                        Text("Start Game")
                            .frame(width: UIScreen.main.bounds.width, height: 50, alignment: .center)
                            .font(.largeTitle)
                            .background(Color.yellow)
                    }

//                    Button(action: {}, label: {
//                        Image("add")
//                    })
                    Text("Score:\(gameVM.score)")
                        .frame(width: UIScreen.main.bounds.width, height: 50, alignment: .center)
                        .font(.largeTitle)
                        .background(Color.green)
                }
                
            }
            
        }
        
//        override func viewDidLoad() {
//            super.viewDidLoad();
//
//            let myButton = UIButton()
//
//            // When user touch myButton, we're going to call loadData method
//            myButton.addTarget(self, action: #selector(self.loadData), forControlEvents: .TouchUpInside)
//
//            // Load the data
//            self.loadData();
//        }
//
//        func loadData() {
//            // code to load data from network, and refresh the interface
//            tableView.reloadData()
//        }
    }
}


struct GameMap_Previews: PreviewProvider {
    static var previews: some View {
        GameMap(gameVM:GameViewModel(), group: testGroup, session: testSession)
            .environmentObject(SettingStorage())
    }
}
