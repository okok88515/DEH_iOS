import SwiftUI
import MapKit
import Combine
import Alamofire

class MapViewModel: ObservableObject {
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage: SettingStorage
    @Published private var cancellable: AnyCancellable?
    @Published private var cancellable2: AnyCancellable?
    @Published var showFilterButton = true
    @Published var formatsIndex: Int = 0
    @Published private var searchText: String = ""
    @Published private var medias: [MediaMulti] = []
    @Published var viewNumbers = -1
    @Published private var commentary: MediaMulti = MediaMulti(data: Data(), format: .Default)
    @Published private var mediaCancellable: [AnyCancellable] = []
    @State var index = 0
    var ids = ["All".localized, "Expert's map".localized, "User's map".localized, "Docent's map".localized]
    var types = ["All".localized, "Image".localized, "Audio".localized, "Video".localized]
    var Transfer = [
        "All".localized: "all",
        "Expert's map".localized: "expert",
        "User's map".localized: "user",
        "Docent's map".localized: "docent",
        "Image".localized: "image",
        "Audio".localized: "audio",
        "Video".localized: "video",
        "Historical Site, Buildings".localized: "古蹟、歷史建築、聚落",
        "Ruins".localized: "遺址",
        "Antique".localized: "古物",
        "Cultural Landscape".localized: "文化景觀",
        "Natural Landscape".localized: "自然景觀",
        "Traditional Art".localized: "傳統藝術",
        "Cultural Artifacts".localized: "民俗及有關文物",
        "Necessities of Life".localized: "食衣住行育樂",
        "Others".localized: "其他"
    ]
    
    func searchXOIs(action: String) {
        print("User icon pressed...")
        print(locationManager.coordinateRegion.center.latitude)
        let parameters: [String: String] = [
            "username": "\(settingStorage.account)",
            "lat": "\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "dis": "\(settingStorage.searchDistance * 1000)",
            "num": "\(settingStorage.searchNumber)",
            "coi_name": coi,
            "action": action,
            "user_id": "\(settingStorage.userID)",
            "password": "\(settingStorage.password)",
            "language": "中文"
        ]
        let url = getNearbyXois[action] ?? ""
        let publisher: DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                self.settingStorage.XOIs["nearby"] = values.value?.results
                print(self.locationManager.coordinateRegion.center.latitude)
                self.settingStorage.mapType = "nearby"
            })
        if action == "searchNearbyPOI" {
            showFilterButton = false
        } else {
            showFilterButton = true
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
    
    func filterPOI(idsIndex: Int, typesIndex: Int) {
        print(locationManager.coordinateRegion.center.latitude)
        let parameters: [String: String] = [
            "username": "\(settingStorage.account)",
            "lat": "\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "dis": "\(settingStorage.searchDistance * 1000)",
            "num": "\(settingStorage.searchNumber)",
            "coi_name": coi,
            "action": "searchNearbyPOI",
            "user_id": "\(settingStorage.userID)",
            "password": "\(settingStorage.password)",
            "language": "中文",
            "format": "\(formatsIndex)"
        ]
        print(formatsIndex)
        let url = getNearbyXois["searchNearbyPOI"] ?? ""
        let publisher: DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher
            .sink(receiveValue: { (values) in
                self.settingStorage.XOIs["nearby"] = values.value?.results
                if self.searchText != "" {
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({ $0.name.contains(self.searchText) })
                }
                if idsIndex != 0 {
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({ $0.creatorCategory == self.Transfer[self.ids[idsIndex]] })
                }
                if typesIndex != 0 {
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({ $0.mediaCategory == self.Transfer[self.types[typesIndex]] })
                }
            })
    }
    
    @ViewBuilder func pinSelector(number: Int, xoiCategory: String) -> some View {
        switch xoiCategory {
        case "poi": Image("player_pin")
        case "loi": ImageWithNumber(number: number)
        case "aoi": Image("player_pin")
        case "soi": ImageWithNumber(number: number)
        default:
            Text("error")
        }
    }
    
    @ViewBuilder func XOIMediaSelector(xoi: XOI) -> some View {
        switch xoi.xoiCategory {
        case "poi":
            if self.medias.isEmpty {
                Text("No media available")
                    .onAppear { print("[DEBUG] XOIMediaSelector: medias array is empty") }
            } else {
                PagingView(index: $index.animation(), maxIndex: self.medias.count - 1) {
                    ForEach(self.medias, id: \.data) { singleMedia in
                        singleMedia.view()
                            .onAppear {
                                print("[DEBUG] Rendering media with format \(singleMedia.mediaFormat.rawValue), data size: \(singleMedia.data.count)")
                            }
                    }
                }
                .onAppear { print("[DEBUG] PagingView initialized with \(self.medias.count) items") }
            }
        case "loi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "aoi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "soi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        default:
            Text("error")
                .onAppear { print("[DEBUG] XOIMediaSelector: Unknown xoiCategory \(xoi.xoiCategory)") }
        }
    }
    
    func getViewerNumber(xoi: XOI) {
        let parameters: Parameters = [
            "poi_id": xoi.id
        ]
        let url = POIClickCountUrl
        let publisher: DataResponsePublisher<ClickCount> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher.sink(receiveValue: { (values) in
            if let count = values.value?.count {
                self.viewNumbers = count
            } else {
                self.viewNumbers = -1
            }
        })
    }
    
    func navigatedAction(xoi: XOI) {
        let srcLocation = MKMapItem.forCurrentLocation()
        let dst = CLLocationCoordinate2D(latitude: xoi.latitude, longitude: xoi.longitude)
        let dstLocation = MKMapItem.init(placemark: MKPlacemark(coordinate: dst, addressDictionary: nil))
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        MKMapItem.openMaps(with: [srcLocation, dstLocation], launchOptions: options)
    }
    
    // Set media data in place
    func getMedia(xoi: XOI) {
        // Clear existing media first
        self.medias.removeAll()
        
        // Check if mediaSet is empty
        if xoi.mediaSet.isEmpty {
            // If no mediaSet, add default image
            self.medias = [MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture)]
            return
        }
        
        // Process each media item
        for media in xoi.mediaSet {
            if media.mediaFormat == 0 || media.mediaUrl.isEmpty {
                self.medias = [MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture)]
                continue
            }
            
            let url = media.mediaUrl
            let publisher = NetworkConnector().getMediaPublisher(url: url)
            
            let cancelable = publisher
                .sink(receiveValue: { [weak self] (values: DataResponse<Data, AFError>) in
                    guard let self = self else { return }
                    
                    if let data = values.data, !data.isEmpty {
                        if let mediaFormat = format(rawValue: media.mediaFormat) {
                            switch mediaFormat {
                            case .Commentary:
                                self.commentary = MediaMulti(data: data, format: mediaFormat)
                            case .Video, .Voice, .Picture:
                                self.medias.append(MediaMulti(data: data, format: mediaFormat))
                            case .Default:
                                print("[DEBUG] Default format encountered for \(url)")
                            }
                        } else {
                            print("[DEBUG] Unknown media format \(media.mediaFormat) for \(url)")
                            self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                        }
                    } else {
                        print("[DEBUG] Failed to fetch media from \(url): \(values.error?.localizedDescription ?? "No data received")")
                        self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                    }
                })
            
            self.mediaCancellable.append(cancelable)
        }
    }
}

// MARK: - Preview Provider (Optional, if needed)
struct MapViewModel_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock MapViewModel for preview
        let mockViewModel = MapViewModel()
        // Add mock data or environment objects if needed
        return EmptyView() // Adjust as needed for your preview setup
            .environmentObject(mockViewModel.settingStorage)
    }
}
