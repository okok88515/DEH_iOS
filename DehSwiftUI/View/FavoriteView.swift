//
//  FavoriteView.swift
//  DehSwiftUI
//
//  Created by 鄭宇軒 on 2023/10/19.
//  Copyright © 2023 mmlab. All rights reserved.
//
import SwiftUI
import Combine
import Alamofire
import MapKit
import SwiftUI

struct FavoriteView: View {
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
    @State var filter_choose:String = "x"
    @State var hide_listState = true
    //nearby search filter deault hide
    @State var showTitle:Bool = true
    @State var POIselected = false
//    @State var favorite_set:[XOI]
//    favorite_set = settingStorage.XOIs["favorite"]
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
                Text("My Favorite".localized)
                    .onAppear{
                        hide_listState = true
                    }
                    .foregroundColor(Color.white)
                Spacer()
                Button(action: {
                    //                    searchXOIs()
                    selectSearchXOI = true
                }){
                    Image("member_funnel")
                        .foregroundColor(.blue)
                }
                .actionSheet(isPresented: $selectSearchXOI){
                    return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                        .default(Text("POI".localized)) {
                            filter_choose = "p"
//                            for(xoi in self.settingStorage.XOIs["favorite"]??[] where xoi.xoiCategory == "poi" )
//                            favorite_set = self.settingStorage.XOIs["favorite"]
                        },
                        .default(Text("LOI".localized)) { filter_choose = "l" },
                        .default(Text("AOI".localized)) { filter_choose = "a" },
                        .default(Text("SOI".localized)) { filter_choose = "s" },
                        .cancel()
                    ])
                }
                
            }
            
            //.frame(height:20)
            .padding([.top, .leading, .trailing])
            //.background(Color.init(UIColor(rgba: lightGreen)))
            
            ZStack {
                DEHMap().onTapGesture {
                    if !hide_listState{
                        hide_listState = true
                    }
                }
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
                    ForEach(self.settingStorage.XOIs["favorite"] ?? []){xoi in
                        XOIRow(xoi:xoi,tabItemName:"favorite")
                            .padding(.horizontal)
                    }.listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    //                    if(filter_choose == "p"){
                    //                        ForEach(self.settingStorage.XOIs[] ?? [] ){poi in
                    //                            ForEach(poi.xoiCategory == "poi"){xoi in
                    //                                XOIRow(xoi:xoi,tabItemName:"favorite")
                    //                            }
                    //                                .padding(.horizontal)
                    //                        }.listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    //
                    //                    }
                    //
                    //
                    //                    else if(filter_choose == "l"){
                    //                        ForEach(self.settingStorage.XOIs["favorite"] ?? []){xoi in XOIRow(xoi:xoi,tabItemName:"favorite",xoiCategory:"loi")
                    //                                .padding(.horizontal)
                    //                        }
                    //                    }
                    //                    else if(filter_choose == "a"){
                    //                        ForEach(self.settingStorage.XOIs["favorite"] ?? []){xoi in XOIRow(xoi:xoi,tabItemName:"favorite",xoiCategory:"aoi")
                    //                                .padding(.horizontal)
                    //                        }.listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    //                    }
                    //                    else if(filter_choose == "s"){
                    //                        ForEach(self.settingStorage.XOIs["favorite"] ?? []){xoi in XOIRow(xoi:xoi,tabItemName:"favorite",xoiCategory:"soi")
                    //                                .padding(.horizontal)
                    //                        }.listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    //                    }
                    //                    else{
                    //                        ForEach(self.settingStorage.XOIs["favorite"] ?? []){xoi in XOIRow(xoi:xoi,tabItemName:"favorite")
                    //                                .padding(.horizontal)
                    //                        }.listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    //                    }
                }
                .frame(width:sideBarWidth)
                .offset(x:-sideBarWidth/3)
                .disabled(hide_listState)
                .hidden(hide_listState)
                
                
                
            }
            .background(Color.init(UIColor(rgba: lightGreen)))
        }
    }
}

extension FavoriteView{
    func selsctXOI (xoi:XOI){
        if (xoi.xoiCategory == "poi"){
            
        }
        
    }
}

struct FavoriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteView()
            .environmentObject(SettingStorage())
    }
}
