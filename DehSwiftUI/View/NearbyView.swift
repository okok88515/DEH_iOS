//
//  NearbyView.swift
//  DehSwiftUI
//
//  Created by 鄭宇軒 on 2023/9/6.
//  Copyright © 2023 mmlab. All rights reserved.
//

import SwiftUI
import MapKit
import Combine
import Alamofire

struct NearbyView: View {
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage:SettingStorage
    @State var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.997, longitude: 120.221),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.7
    @State var poiIndex:Int? = nil
    @State var idsIndex:Int = 0
    @State var typesIndex:Int = 0
    @State var formatsIndex:Int = 0
    @State var selection: Int? = nil
    @State var selectSearchXOI = false
    @State private var cancellable: AnyCancellable?
    //left list default hide
    @State var hide_listState = true
    //nearby search filter deault hide
    @State var filterState = false
    @State var showFilterButton = true
    @State var showTitle:Bool = true
    @State var POIselected = false
    
    var body: some View {
        
        VStack (){
            
            HStack{
                //left list button
                Button{
                    if hide_listState{
                        hide_listState = false
                    }
                    else{
                        hide_listState = true
                    }
                }label: {
                    Image("member_grouplist")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                Text("Searched Xois".localized)
                    .onAppear{
                        hide_listState = true
                    }
                    .foregroundColor(Color.white)
                
                Spacer()
                                
                Button {
                    filterState = true
                    
                } label: {
                    Image("member_search")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .disabled(showFilterButton)
                .hidden(showFilterButton)
                
                Button(action: {
                    print("map_locate tapped")
                    selectSearchXOI = true
                    
                }) {
                    Image("member_funnel")
                        .foregroundColor(.blue)
                }
                .actionSheet(isPresented: $selectSearchXOI) {
                    
                    if app == "dehMicro" || app == "sdcMicro"{
                        return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                            .default(Text("POI".localized)) {
                                searchXOIs(action: "searchNearbyPOI") },
                            .cancel()
                        ])
                    }
                    else {
                        
                        return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                            .default(Text("POI".localized)) { searchXOIs(action: "searchNearbyPOI"); POIselected = true
                            },
                            .default(Text("LOI".localized)) { searchXOIs(action: "searchNearbyLOI") },
                            .default(Text("AOI".localized)) { searchXOIs(action: "searchNearbyAOI") },
                            .default(Text("SOI".localized)) { searchXOIs(action: "searchNearbySOI") },
                            .cancel()
                        ])
                        
                    }
                    
                }
            }
            
            //.frame(height:20)
            .padding([.top, .leading, .trailing])
            //.background(Color.init(UIColor(rgba: lightGreen)))
            
            ZStack {
                //DEHMap()
                Map(coordinateRegion: $locationManager.coordinateRegion, annotationItems: settingStorage.XOIs[settingStorage.mapType] ?? []){xoi in
                    MapAnnotation(
                        coordinate: xoi.coordinate,
                        anchorPoint: CGPoint(x: 0.5, y: 0.5)
                    ) {
                        NavigationLink("", tag: settingStorage.XOIs[settingStorage.mapType]?.firstIndex(of: xoi) ?? 0, selection: $selection, destination: {destinationSelector(xoi:xoi)})
                        pin(xoi: xoi, selection: $selection)
                    }
                }
                .onTapGesture {
                    if !hide_listState{
                        hide_listState = true
                    }
                }.overlay(
                    ZStack{
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                Image("sniper_target")
                                Spacer()
                            }
                            Spacer()
                        }
                        VStack{
                            Spacer()
                            HStack{
                                Button(action: {
                                    print("gps tapped")
                                    locationManager.updateLocation()
                                }) {
                                    Image("gps")
                                }
                                .padding(.leading, 10.0)
                                Spacer()
    //                            Button(action: {
    //                                print("alert tapped")
    //                            }) {
    //                                Image("alert")
    //                            }
    //                            .padding(.trailing, 10.0)
                            }
                            .padding(.bottom,30.0)
                        }
                    }
                )
//                TabView{
//                    
//                    DEHMap().tabItem {
//                        Text("map".localized)
//                        Image("member_smap").foregroundColor(.blue)
//                    }
////                    .scaledToFill()
//                    
//                    TabViewElement(title: "Searched Xois".localized, image1: "member_smap", image2: "member_funnel",tabItemImage:"member_grouplist",tabItemName: "nearby")
//                    
//                }
                
                List{
                    
                    ForEach(self.settingStorage.XOIs["nearby"] ?? []){xoi in
                        XOIRow(xoi:xoi,tabItemName:"nearby")
                            .padding(.horizontal)
                    }
                    .listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    
                }
                .frame(width:sideBarWidth)
                .offset(x:-sideBarWidth/3)
                .disabled(hide_listState)
                .hidden(hide_listState)
                
                
                if filterState{
                    FilterView(idsIndex: $idsIndex, typesIndex: $typesIndex, formatsIndex: $formatsIndex, myViewState: $filterState, locationManager: locationManager)
                }
            }
        }.background(Color.init(UIColor(rgba: lightGreen)))
    }
}

extension NearbyView{
    func searchXOIs(action:String){
        print("User icon pressed...")
        print(locationManager.coordinateRegion.center.latitude)
        let parameters:[String:String] = [
            "username": "\(settingStorage.account)",
            "lat" :"\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "dis": "\(settingStorage.searchDistance * 1000)",
            "num": "\(settingStorage.searchNumber)",
            "coi_name": coi,
            "action": action,
            "user_id": "\(settingStorage.userID)",
            "password":"\(settingStorage.password)",
            "language":"中文"
        ]
        let url = getNearbyXois[action] ?? ""
        let publisher:DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                self.settingStorage.XOIs["nearby"] = values.value?.results
                print(locationManager.coordinateRegion.center.latitude)
                self.settingStorage.mapType = "nearby"
            })
        if action == "searchNearbyPOI "{
            showFilterButton = true
        }
        else{
            showFilterButton = false
        }
        hide_listState = false
       

    }
    @ViewBuilder func destinationSelector(xoi:XOI) -> some View{
        switch xoi.xoiCategory {
        case "poi": XOIDetail(xoi:xoi)
        case "loi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "aoi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "soi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        default:
            Text("error")
        }
    }
}



struct NearbyView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyView()
            .environmentObject(SettingStorage())
    }
}
