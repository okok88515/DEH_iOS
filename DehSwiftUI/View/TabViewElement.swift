//
//  TabViewElement.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2020/12/2.
//  Copyright © 2020 mmlab. All rights reserved.
//

import SwiftUI
import Combine
import Alamofire
import MapKit

struct TabViewElement: View {
    @State var title: String
    var image1: String
    var image2: String
    var tabItemImage: String
    var tabItemName: String
    @State var alertString:String = ""
    @State var alertState:Bool = false
    @ObservedObject var xoiViewModel = XOIViewModel()
    @EnvironmentObject var settingStorage:SettingStorage
    @ObservedObject var locationManager = LocationManager()
    @State var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.997, longitude: 120.221),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State var selectSearchXOI = false
    @State private var cancellable: AnyCancellable?
    @State var group = Group(id: 0, name: "-111", leaderId: 0, info: "")
    @State var region = Field(id: 0, name: "-111", info: "")
    @State var selectOverState:Bool = false
    @State var exitRegionState:Bool = false
    @State var selection: Int? = nil
    @State var POIselected = false
    //left list default hide
    @State var hide_listState = true
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.7
    var body: some View {
        VStack{
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
                Text(title)
                    .onAppear{
                        hide_listState = true
                        if(group.name != "-111"){
                            title = group.name
                        }
                        if(region.name != "-111"){
                            title = region.name
                        }
                    }
                    .foregroundColor(Color.white)
                Spacer()
                
//                if (image1 == "member_smap"){
//                    NavigationLink(tag: 5, selection: $selection, destination: {DEHMap()}) {
//                        Button{
//                            print("map tapped")
//                            self.selection = 5
//                        } label: {
//                            Image("member_smap")
//
//                        }
//                    }
//
//                }
                //this will cause an warning but no idea about it
                if (image1 == "member_grouplist" ){
                    NavigationLink(destination: GroupList(group: $group)) {
                        Image(image1)
                    }
                }
                //remember to design a icon for member_regionlist date:0302
                if (image1 == "member_regionlist" && selectOverState == false){
                    NavigationLink(destination: RegionView(selectOverState: $selectOverState,region: $region)) {
                        Image("member_search")
                    }
                }
                if (image1 == "member_regionlist" && selectOverState == true){
                    Button{
                        self.exitRegionState = true
                        //                        print(exitRegionState)
                    }
                    label:{
                        Image("member_x")
                            .resizable()
                            .frame(width:20, height:20)
                    }
//                    .actionSheet(isPresented: $exitRegionState) {
//                        actionSheetBuilder(tabItemName:tabItemName)
//                    }
                    
                    .alert(title, isPresented: $exitRegionState) {
                                
                        Button("Confirm".localized, action: {
                                    // Handle acknowledgement.
                                    self.settingStorage.XOIs[tabItemName] = []
                                    self.region = Field(id: 0, name: "-111", info: "")
                                    self.title = "Region Interests".localized
                                    self.selectOverState = false
                                })
                        Button("Cancel".localized, action: {})
                                
                            } message: {
                                Text("Are you sure to exit this region?".localized)
                            }
//                    .alert(isPresented: $exitRegionState) { () -> Alert in
//
////                        return Alert(title: Text("yes"),dismissButton:.default(Text("OK".localized), action:{}))
//
//                        return Alert(title: Text("Join".localized),
//                                    message: Text("Join".localized),
//                                    primaryButton: .default(Text("Yes".localized),
//                                    action: {
//                                        self.settingStorage.XOIs[tabItemName] = []
//                                        self.region = Field(id: 0, name: "-111", info: "")
//                                            }),
//                                    secondaryButton: .default(Text("No".localized), action: {}))
//                            }
                }
                    
//                }
//                NavigationLink(destination: GroupList(group: $group)) {
//                    Image(image1).hidden(image1=="Empty")
//                }
//                .disabled(image1=="Empty")

                
                Button(action: {
//                    searchXOIs()
                    selectSearchXOI = true
                }){
                    Image(image2).hidden(image2=="Empty")
                }
                .disabled(image2=="Empty")
                .actionSheet(isPresented: $selectSearchXOI) {
                    actionSheetBuilder(tabItemName:tabItemName)
                }
                
            }
            //.frame(height:20)
            .padding([.top, .leading, .trailing])
            
            ZStack {
                //also show nearby xoi pin in the list
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
                
                List{
                    
                    ForEach(self.settingStorage.XOIs[tabItemName] ?? []){xoi in
                        XOIRow(xoi:xoi,tabItemName:tabItemName)
                            .padding(.horizontal)
                    }
                    .listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                    
                }
                .frame(width:sideBarWidth)
                .offset(x:-sideBarWidth/3)
                .disabled(hide_listState)
                .hidden(hide_listState)
            }
        }
        
        .background(Color.init(UIColor(rgba: lightGreen)))
        .alert(isPresented: $alertState) { () -> Alert in
            return Alert(title: Text(alertString),
                 dismissButton:.default(Text("OK".localized), action: {}))
        }
        .tabItem{
            Image(tabItemImage)
            Text(tabItemName.localized)
                .foregroundColor(.white)
            
        }
        

    }
    
}
extension TabViewElement{
    func searchXOIs(action: String) {
        print("User icon pressed...")
        
        // Only check group selection for group tab
        if (group.id == 0) && (tabItemName == "group") {
            alertString = "please choose group".localized
            alertState = true
            return
        }
        
        // Determine XOI category from action (for proper mapping later)
        let xoiCategory: String
        if action.contains("POI") {
            xoiCategory = "poi"
        } else if action.contains("LOI") {
            xoiCategory = "loi"
        } else if action.contains("AOI") {
            xoiCategory = "aoi"
        } else if action.contains("SOI") {
            xoiCategory = "soi"
        } else {
            xoiCategory = "poi"
        }
        
        let parameters: [String: String] = [
            "username": settingStorage.account,
            "lat": "\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "dis": "\(settingStorage.searchDistance * 1000)",
            "num": "\(settingStorage.searchNumber)",
            "coi_name": coi,
            "action": action,
            "user_id": "\(settingStorage.userID)",
            "group_id": "\(group.id)",
            "region_id": "\(region.id)",
            "language": "中文"
        ]
        
        print(action)
        let url = getXois[action] ?? ""
        let publisher: DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(
            url: url,
            para: parameters
        )
        
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                if let xois = values.value?.results {
                    if !xois.isEmpty {
                        // Set the correct category for each XOI
                        let categorizedXois = xois.map { xoi -> XOI in
                            let updatedXoi = xoi
                            updatedXoi.xoiCategory = xoiCategory
                            return updatedXoi
                        }
                        self.settingStorage.XOIs[self.tabItemName] = categorizedXois
                        self.settingStorage.mapType = self.tabItemName
                        self.hide_listState = false
                    } else {
                        self.alertString = "No Data".localized
                        self.alertState = true
                    }
                } else {
                    self.alertString = "No Data".localized
                    self.alertState = true
                }
            })
    }
    func actionSheetBuilder(tabItemName:String) -> ActionSheet{
        print(tabItemName)
        if(tabItemName == "group"){
            return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                .default(Text("Group POI")) { searchXOIs(action: "searchGroupPOI") },
                .default(Text("Group LOI")) { searchXOIs(action: "searchGroupLOI") },
                .default(Text("Group AOI")) { searchXOIs(action: "searchGroupAOI") },
                .default(Text("Group SOI")) { searchXOIs(action: "searchGroupSOI") },
                .default(Text("Group My POI")) { searchXOIs(action: "searchGroupMyPOI") },
                .default(Text("Group My LOI")) { searchXOIs(action: "searchGroupMyLOI") },
                .default(Text("Group My AOI")) { searchXOIs(action: "searchGroupMyAOI") },
                .default(Text("Group My SOI")) { searchXOIs(action: "searchGroupMySOI") },
                .cancel()
            ])
        }
        else if(tabItemName == "region"){
            return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                .default(Text("Region POI")) { searchXOIs(action: "searchRegionPOI") },
                .default(Text("Region LOI")) { searchXOIs(action: "searchRegionLOI") },
                .default(Text("Region AOI")) { searchXOIs(action: "searchRegionAOI") },
                .default(Text("Region SOI")) { searchXOIs(action: "searchRegionSOI") },
                .cancel()
            ])
        }
        //maybe need favorite view since favorite would be miss
//        else if(tabItemName == "favorite"){
//            return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
//                .default(Text("POI")) { self.settingStorage.XOIs = self.settingStorage.XOIs["favorite"]?[0].xoiCategory == ["poi"]  },
//                .default(Text("LOI")) { let _ = print( self.settingStorage.XOIs["favorite"]?[0].xoiCategory==["loi"]) },
//                .default(Text("AOI")) { let _ = print( self.settingStorage.XOIs["favorite"]?[0].xoiCategory==["aoi"]) },
//                .default(Text("SOI")) { let _ = print( self.settingStorage.XOIs["favorite"]?[0].xoiCategory==["soi"]) },
//                .cancel()
//            ])
//        }
        
        else {
            return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                .default(Text("POI")) { searchXOIs(action: "searchMyPOI") },
                .default(Text("LOI")) { searchXOIs(action: "searchMyLOI") },
                .default(Text("AOI")) { searchXOIs(action: "searchMyAOI") },
                .default(Text("SOI")) { searchXOIs(action: "searchMySOI") },
                .cancel()
            ])
        }
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



struct TabViewElement_Previews: PreviewProvider {
    static var previews: some View {
        TabViewElement(title: "page2", image1: "member_regionlist", image2: "member_funnel",tabItemImage: "member_favorite",tabItemName: "favorirte")
            .environmentObject(SettingStorage())
    }
}

