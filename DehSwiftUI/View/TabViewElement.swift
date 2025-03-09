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
    @State var alertString: String = ""
    @State var alertState: Bool = false
    @ObservedObject var xoiViewModel = XOIViewModel()
    @EnvironmentObject var settingStorage: SettingStorage
    @ObservedObject var locationManager = LocationManager()
    @State var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.997, longitude: 120.221),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State var selectSearchXOI = false
    @State private var cancellable: AnyCancellable?
    @State var group = Group(id: 0, name: "-111", leaderId: 0, info: "")
    @State var region = Field(id: 0, name: "-111", info: "")
    @State var selectOverState: Bool = false
    @State var exitRegionState: Bool = false
    @State var selection: Int? = nil
    @State var POIselected = false
    // Left list default hide
    @State var hide_listState = true
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.7
    
    var body: some View {
        VStack {
            HStack {
                // Left list button
                Button {
                    if hide_listState {
                        hide_listState = false
                    } else {
                        hide_listState = true
                    }
                } label: {
                    Image("member_grouplist")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                Text(title)
                    .onAppear {
                        hide_listState = true
                        if (group.name != "-111") {
                            title = group.name
                        }
                        if (region.name != "-111") {
                            title = region.name
                        }
                    }
                    .foregroundColor(Color.white)
                Spacer()
                
                if (image1 == "member_grouplist") {
                    NavigationLink(destination: GroupList(group: $group)) {
                        Image(image1)
                    }
                }
                if (image1 == "member_regionlist" && selectOverState == false) {
                    NavigationLink(destination: RegionView(selectOverState: $selectOverState, region: $region)) {
                        Image("member_search")
                    }
                }
                if (image1 == "member_regionlist" && selectOverState == true) {
                    Button {
                        self.exitRegionState = true
                    } label: {
                        Image("member_x")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .alert(title, isPresented: $exitRegionState) {
                        Button("Confirm".localized, action: {
                            self.settingStorage.XOIs[tabItemName] = []
                            self.region = Field(id: 0, name: "-111", info: "")
                            self.title = "Region Interests".localized
                            self.selectOverState = false
                        })
                        Button("Cancel".localized, action: {})
                    } message: {
                        Text("Are you sure to exit this region?".localized)
                    }
                }
                
                Button(action: {
                    selectSearchXOI = true
                }) {
                    Image(image2).hidden(image2 == "Empty")
                }
                .disabled(image2 == "Empty")
                .actionSheet(isPresented: $selectSearchXOI) {
                    actionSheetBuilder(tabItemName: tabItemName)
                }
            }
            .padding([.top, .leading, .trailing])
            
            ZStack {
                // Also show nearby XOI pins in the list
                Map(coordinateRegion: $locationManager.coordinateRegion, annotationItems: settingStorage.XOIs[settingStorage.mapType] ?? []) { xoi in
                    MapAnnotation(
                        coordinate: xoi.coordinate,
                        anchorPoint: CGPoint(x: 0.5, y: 0.5)
                    ) {
                        NavigationLink("", tag: settingStorage.XOIs[settingStorage.mapType]?.firstIndex(of: xoi) ?? 0, selection: $selection, destination: { destinationSelector(xoi: xoi) })
                        pin(xoi: xoi, selection: $selection)
                    }
                }
                .onTapGesture {
                    if !hide_listState {
                        hide_listState = true
                    }
                }
                .overlay(
                    ZStack {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("sniper_target")
                                Spacer()
                            }
                            Spacer()
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Button(action: {
                                    print("gps tapped")
                                    locationManager.updateLocation()
                                }) {
                                    Image("gps")
                                }
                                .padding(.leading, 10.0)
                                Spacer()
                            }
                            .padding(.bottom, 30.0)
                        }
                    }
                )
                
                List {
                    ForEach(self.settingStorage.XOIs[tabItemName] ?? []) { xoi in
                        XOIRow(xoi: xoi, tabItemName: tabItemName)
                            .padding(.horizontal)
                    }
                    .listRowBackground(Color.init(UIColor(rgba: darkGreen)))
                }
                .frame(width: sideBarWidth)
                .offset(x: -sideBarWidth / 3)
                .disabled(hide_listState)
                .hidden(hide_listState)
            }
        }
        .background(Color.init(UIColor(rgba: lightGreen)))
        .alert(isPresented: $alertState) { () -> Alert in
            return Alert(title: Text(alertString),
                         dismissButton: .default(Text("OK".localized), action: {}))
        }
        .tabItem {
            Image(tabItemImage)
            Text(tabItemName.localized)
                .foregroundColor(.white)
        }
    }
}

extension TabViewElement {
    func searchXOIs(action: String) {
        print("[DEBUG] Starting XOI search for action: \(action)")
        
        // Group validation check
        if (group.id == 0) && (tabItemName == "group") {
            print("[DEBUG] No group selected for group tab")
            alertString = "please choose group".localized
            alertState = true
            return
        }
        
        // Determine XOI category
        let xoiCategory: String = {
            if action.contains("POI") { return "poi" }
            if action.contains("LOI") { return "loi" }
            if action.contains("AOI") { return "aoi" }
            if action.contains("SOI") { return "soi" }
            return "poi"
        }()
        print("[DEBUG] Determined xoiCategory: \(xoiCategory)")

        // Build parameters based on action type
        var parameters: [String: Any]
        
        if action.contains("Group") {
            // Group XOI parameters
            parameters = [
                "latitude": locationManager.coordinateRegion.center.latitude,
                "longitude": locationManager.coordinateRegion.center.longitude,
                "distance": settingStorage.searchDistance * 1000,
                "number": settingStorage.searchNumber,
                "format": "image",
                "coiName": coi, // Assuming 'coi' is defined elsewhere in your code
                "language": "中文",
                "groupId": group.id
            ]
        } else if action.contains("Region") {
            // Region XOI parameters
            parameters = [
                "latitude": locationManager.coordinateRegion.center.latitude,
                "longitude": locationManager.coordinateRegion.center.longitude,
                "distance": settingStorage.searchDistance * 1000,
                "number": settingStorage.searchNumber,
                "format": "image",
                "coiName": coi,
                "language": "中文",
                "regionId": region.id
            ]
        } else {
            // User XOI parameters
            parameters = [
                "username": settingStorage.account,
                "latitude": locationManager.coordinateRegion.center.latitude,
                "longitude": locationManager.coordinateRegion.center.longitude,
                "number": settingStorage.searchNumber,
                "coiName": coi,
                "distance": settingStorage.searchDistance * 1000,
                "language": "中文"
            ]
        }
        print("[DEBUG] Prepared parameters: \(parameters)")

        let url = getXois[action] ?? ""
        print("[DEBUG] Fetching from URL: \(url) with parameters: \(parameters)")

        let publisher: DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(
            url: url,
            para: parameters,
            addLogs: true
        )
        
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                print("[DEBUG] Received response: \(values.debugDescription)")
                
                if let error = values.error {
                    print("[DEBUG] Request failed with error: \(error.localizedDescription)")
                    self.alertString = "Error fetching data".localized
                    self.alertState = true
                    return
                }
                
                if let message = values.value?.message {
                    print("[DEBUG] API returned message: \(message)")
                    if message == "not login" {
                        self.alertString = "Please login first".localized
                        self.alertState = true
                    }
                    return
                }
                
                if let xois = values.value?.results {
                    print("[DEBUG] Received \(xois.count) XOIs")
                    if !xois.isEmpty {
                        let categorizedXois = xois.map { xoi -> XOI in
                            let updatedXoi = xoi
                            updatedXoi.xoiCategory = xoiCategory
                            print("[DEBUG] Processing XOI \(xoi.id): \(xoi.name), MediaSet count: \(xoi.mediaSet.count)")
                            xoi.mediaSet.forEach { media in
                                print("[DEBUG] - Media: format=\(media.mediaFormat), url=\(media.mediaUrl)")
                            }
                            return updatedXoi
                        }
                        self.settingStorage.XOIs[self.tabItemName] = categorizedXois
                        self.settingStorage.mapType = self.tabItemName
                        self.hide_listState = false
                        print("[DEBUG] Stored \(categorizedXois.count) XOIs in settingStorage[\(self.tabItemName)]")
                    } else {
                        print("[DEBUG] No XOIs found in response")
                        self.alertString = "No Data".localized
                        self.alertState = true
                    }
                } else {
                    print("[DEBUG] No results in response")
                    self.alertString = "No Data".localized
                    self.alertState = true
                }
            })
    }
    
    func actionSheetBuilder(tabItemName: String) -> ActionSheet {
            print(tabItemName)
            if (tabItemName == "group") {
                return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                    .default(Text("Group POI")) { searchXOIs(action: "searchGroupPOI") },
                    .default(Text("Group LOI")) { searchXOIs(action: "searchGroupLOI") },
                    .default(Text("Group AOI")) { searchXOIs(action: "searchGroupAOI") },
                    .default(Text("Group SOI")) { searchXOIs(action: "searchGroupSOI") },
                    .cancel()
                ])
            } else if (tabItemName == "region") {
                return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                    .default(Text("Region POI")) { searchXOIs(action: "searchRegionPOI") },
                    .default(Text("Region LOI")) { searchXOIs(action: "searchRegionLOI") },
                    .default(Text("Region AOI")) { searchXOIs(action: "searchRegionAOI") },
                    .default(Text("Region SOI")) { searchXOIs(action: "searchRegionSOI") },
                    .cancel()
                ])
            } else {
                return ActionSheet(title: Text("Select Search XOIs"), message: Text(""), buttons: [
                    .default(Text("POI")) { searchXOIs(action: "searchMyPOI") },
                    .default(Text("LOI")) { searchXOIs(action: "searchMyLOI") },
                    .default(Text("AOI")) { searchXOIs(action: "searchMyAOI") },
                    .default(Text("SOI")) { searchXOIs(action: "searchMySOI") },
                    .cancel()
                ])
            }
        }
    
    @ViewBuilder func destinationSelector(xoi: XOI) -> some View {
        switch xoi.xoiCategory {
        case "poi": XOIDetail(xoi: xoi)
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
        TabViewElement(title: "page2", image1: "member_regionlist", image2: "member_funnel", tabItemImage: "member_favorite", tabItemName: "favorite")
            .environmentObject(SettingStorage.shared)
    }
}
