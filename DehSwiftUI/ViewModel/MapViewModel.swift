//
//  MapViewModel.swift
//  DehSwiftUI
//
//  Created by 廖偉博 on 2022/12/22.
//  Copyright © 2022 mmlab. All rights reserved.
//

import SwiftUI
import MapKit
import Combine
import Alamofire

class MapViewModel:ObservableObject {
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage:SettingStorage
    @Published private var cancellable: AnyCancellable?
    @Published private var cancellable2: AnyCancellable?
    @Published var showFilterButton = true
    @Published var formatsIndex:Int = 0
    @Published private var searchText:String = ""
    @Published private var medias:[MediaMulti] = []
    @Published var viewNumbers = -1
    @Published private var commentary:MediaMulti = MediaMulti(data: Data(), format: .Default)
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
        let publisher:DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                self.settingStorage.XOIs["nearby"] = values.value?.results
                print(self.locationManager.coordinateRegion.center.latitude)
                self.settingStorage.mapType = "nearby"
            })
        if action == "searchNearbyPOI"{
            showFilterButton = false
        }
        else{
            showFilterButton = true
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
    func filterPOI(idsIndex:Int, typesIndex:Int){
        print(locationManager.coordinateRegion.center.latitude)
        let parameters:[String:String] = [
            "username": "\(settingStorage.account)",
            "lat" :"\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "dis": "\(settingStorage.searchDistance * 1000)",
            "num": "\(settingStorage.searchNumber)",
            "coi_name": coi,
            "action": "searchNearbyPOI",
            "user_id": "\(settingStorage.userID)",
            "password":"\(settingStorage.password)",
            "language":"中文",
            "format":"\(formatsIndex)"
        ]
        print(formatsIndex)
        let url = getNearbyXois["searchNearbyPOI"] ?? ""
        let publisher:DataResponsePublisher<XOIList> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher
            .sink(receiveValue: {(values) in
                self.settingStorage.XOIs["nearby"] = values.value?.results
                if self.searchText != "" {
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({$0.name.contains(self.searchText)})
                }
                if idsIndex != 0{
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({$0.creatorCategory==self.Transfer[self.ids[idsIndex]]})
                }
                if typesIndex != 0{
                    self.settingStorage.XOIs["nearby"] = (self.settingStorage.XOIs["nearby"] ?? []).filter({$0.mediaCategory==self.Transfer[self.types[typesIndex]]})
                }
            })
    }
    @ViewBuilder func pinSelector(number:Int,xoiCategory:String) -> some View{
        switch xoiCategory {
        case "poi": Image("player_pin")
        case "loi": ImageWithNumber(number: number)
        case "aoi": Image("player_pin")
        case "soi": ImageWithNumber(number: number)
        default:
            Text("error")
        }
    }
    @ViewBuilder func XOIMediaSelector(xoi:XOI) -> some View{
        switch xoi.xoiCategory {
        case "poi":
            PagingView(index: $index.animation(), maxIndex: medias.count - 1) {
                ForEach(self.medias, id: \.data) {
                    singleMedia in
                    singleMedia.view()
                }
            }
        case "loi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "aoi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "soi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        default:
            Text("error")
        }
    }
    
    
    func getViewerNumber(xoi: XOI){
        let parameters:Parameters = [
            "poi_id": xoi.id
        ]
        let url = POIClickCountUrl
        let publisher:DataResponsePublisher<ClickCount> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable = publisher.sink(receiveValue: {(values) in
                if let _ = values.value?.count{
                    self.viewNumbers = values.value?.count ?? -1
                }
                
            })
        }
    func addPoiCount(xoi: XOI){
        let parameters:Parameters = [
            "user_id": settingStorage.userID,
            "ip":"127.0.0.1",
            "page":"/API/test/poi_detail/\(xoi.id)"
        ]
        let url = addPoiCountUrl
        let publisher:DataResponsePublisher<Result> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.cancellable2 = publisher
            .sink(receiveValue: {(values) in
                    print(values.value?.result ?? "")
            })
    }
    
    func navigatedAction(xoi: XOI) {
        let srcLocation = MKMapItem.forCurrentLocation()
        let dst = CLLocationCoordinate2D(latitude: xoi.latitude, longitude: xoi.longitude)
        let dstLocation = MKMapItem.init(placemark: MKPlacemark(coordinate: dst, addressDictionary: nil))
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        MKMapItem.openMaps(with: [srcLocation, dstLocation], launchOptions: options)
    }
    //set media data in place
    func getMedia(xoi: XOI){
        
        //        let format = [
        //            "Commentary": 8,
        //            "Video": 4,
        //            "Voice": 2,
        //            "Picture": 1,
        //        ]
        if let _ = xoi.media_set{
            //
            for (_,media) in xoi.media_set.enumerated(){
                if media.media_format == 0 || media.media_type == ""{
                    medias = [MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: format.Picture)]
                    continue
                }
                let url = media.media_url
                let publisher:DataResponsePublisher = NetworkConnector().getMediaPublisher(url: url)
                
                //            self.mediaCancellable[index] = publisher
                let cancelable = publisher
                    .sink(receiveValue: {(values) in
                        if let formatt = format(rawValue: media.media_format){
                            if let data = values.data{
                                switch formatt{
                                case format.Commentary:
                                    self.commentary = MediaMulti(data:data,format: formatt)
                                case .Video:
                                    fallthrough
                                case .Voice:
                                    fallthrough
                                case .Picture:
                                    self.medias.append(MediaMulti(data:data,format: formatt))
                                case .Default:
                                    print("default")
                                }
                                
                            }
                        }
                        //                    print(values.data?.JsonPrint())
                        switch media.media_format{
                        case format.Commentary.rawValue:
                            print("Commentary")
                        case format.Video.rawValue:
                            print("Video")
                        case format.Voice.rawValue:
                            print("Voice")
                        case format.Picture.rawValue:
                            print("Picture")
                            //                        print(values.debugDescription)
                            //                        images.append(UIImage(data: values.data ?? Data()) ?? UIImage())
                        default:
                            print()
                        }
                        //                    self.mediaCancellable?.cancel()
                        
                        
                    })
                self.mediaCancellable.append(cancelable)
                //
            }
        }
        else{
            medias = [MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: format.Picture)]
            //            images = [UIImage(imageLiteralResourceName: "none")]
        }
    }
}
