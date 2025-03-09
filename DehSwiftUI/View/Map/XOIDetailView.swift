import SwiftUI
import Alamofire
import Combine
import CryptoKit
import MapKit

struct XOIDetail: View {
    var xoi: XOI
    
    // Only for favorite used
    @EnvironmentObject var settingStorage: SettingStorage
    @State var viewNumbers = -1
    @State private var cancellable: AnyCancellable?
    @State private var cancellable2: AnyCancellable?
    @State private var mediaCancellable: [AnyCancellable] = []
    @State private var medias: [MediaMulti] = []
    @State private var commentary: MediaMulti?  // Changed to optional
    @State var index = 0
    @State private var showingAlert = false
    @State private var showingShare = false
    @State private var showingSheet = false
    @State private var isLoading = true
    var secondimage: String
    
    init(xoi: XOI, secondimage: String = "") {
        self.xoi = xoi
        self.secondimage = secondimage
    }
    
    var body: some View {
        ScrollView {
            VStack {
                if isLoading {
                    ProgressView("Loading media...")
                        .frame(height: 400)
                } else {
                    XOIMediaSelector(xoi: xoi)
                        .frame(height: 400.0)
                        .onAppear {
                            print("[DEBUG] XOIMediaSelector rendered with \(medias.count) medias")
                        }
                }
                
                VStack(alignment: .leading) {
                    HStack() {
                        Text(xoi.name)
                            .font(.title)
                        Spacer()
                        Image(xoi.creatorCategory)
                        
                        Button(action: {
                            print("favorite pressed")
                            if let index = settingStorage.XOIs["favorite"]?.firstIndex(of: xoi) {
                                settingStorage.XOIs["favorite"]?.remove(at: index)
                            } else {
                                settingStorage.XOIs["favorite"]?.append(xoi)
                                showingAlert = true
                            }
                        }) {
                            Image("heart")
                        }
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("Add to favorite".localized))
                        }
                        
                        Button(action: {
                            print("more pressed")
                            showingSheet = true
                        }) {
                            Image("more")
                        }
                        .actionSheet(isPresented: $showingSheet) {
                            ActionSheet(title: Text("Select more options".localized), message: Text(""), buttons: [
                                .default(Text("Guide to POI".localized)) {
                                    navigatedAction()
                                },
                                .cancel()
                            ])
                        }
                    }
                    HStack {
                        Text("Voice Commentary")
                            .foregroundColor(Color.white)
                        Spacer()
                        if let commentaryMedia = commentary {
                            // Use the MediaView instead of direct view() method
                            MediaView(mediaMulti: commentaryMedia)
                        } else {
                            Text("No Commentary").foregroundColor(.gray)
                        }
                    }
                    .frame(height: 50.0)  // Increased height for better touch area
                    .background(Color.init(UIColor(rgba:"#24c08c")))
                    .cornerRadius(8)  // Added corner radius
                    .padding(.vertical, 4)  // Added padding
                    
                    Text("View Numbers: " + String(viewNumbers).hidden(viewNumbers == -1))
                    Text(xoi.detail)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                Spacer()
                VStack(spacing: 25) {
                    if let tempContainedXOIs = xoi.containedXOIs {
                        ForEach(tempContainedXOIs) { xoi in
                            NavigationLink(destination: XOIDetail(xoi: xoi)) {
                                HStack(spacing: 12) {
                                    Spacer()
                                    Text("#\(getIndex(xoi: xoi) + 1)")
                                        .fontWeight(.semibold)
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(xoi.name)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(xoi.xoiCategory.checkImageExist(defaultPic: "none"))
                                    Image(secondImage(xoi.creatorCategory.checkImageExist(defaultPic: "none")))
                                    Image(xoi.mediaCategory.checkImageExist(defaultPic: "none"))
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            print("[DEBUG] XOIDetail onAppear for XOI \(xoi.id): \(xoi.name)")
            print("[DEBUG] Initial mediaSet: \(xoi.mediaSet.map { "format=\($0.mediaFormat), url=\($0.mediaUrl)" })")
            getViewerNumber()
            getMedia()
        }
        .onDisappear {
            // Stop any playing audio when leaving the view
            if let commentaryMedia = commentary, commentaryMedia.isPlaying {
                Sounds.stopAudio()
            }
            
            for media in medias where media.isPlaying {
                Sounds.stopAudio()
            }
        }
        .navigationBarItems(trailing: Button {
            self.showingShare = true
        } label: {
            Image(systemName: "square.and.arrow.up.on.square.fill")
                .foregroundColor(.blue)
        }
        .sheet(isPresented: $showingShare, onDismiss: { print("show shareSheet") }, content: {
            ActivityViewController(activityItems: [URL(string: "http://deh.csie.ncku.edu.tw/poi_detail/" + String(xoi.id))!])
        }))
    }
    // MARK: - Helper Functions
    func secondImage(_ originalString: String) -> String {
        if self.secondimage != "public" && self.secondimage != "private" {
            return originalString
        } else if xoi.open == true {
            return "public"
        } else if xoi.open == false {
            return "private"
        } else {
            return "none"
        }
    }
    
    func getIndex(xoi: XOI) -> Int {
        if let tempContainedXOIs = self.xoi.containedXOIs {
            return tempContainedXOIs.firstIndex { Cxoi in
                Cxoi.id == xoi.id
            } ?? 0
        }
        return 0
    }
    
    @ViewBuilder func XOIMediaSelector(xoi: XOI) -> some View {
        switch xoi.xoiCategory {
        case "poi":
            if medias.isEmpty {
                Text("No media available")
                    .onAppear { print("[DEBUG] XOIMediaSelector: medias array is empty") }
            } else {
                PagingView(index: $index.animation(), maxIndex: medias.count - 1) {
                    ForEach(self.medias, id: \.data) { singleMedia in
                        // Use the MediaView instead of direct view() method
                        MediaView(mediaMulti: singleMedia)
                            .onAppear {
                                print("[DEBUG] Rendering media with format \(singleMedia.mediaFormat.rawValue), data size: \(singleMedia.data.count)")
                            }
                    }
                }
                .onAppear { print("[DEBUG] PagingView initialized with \(medias.count) items") }
            }
        case "loi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "aoi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        case "soi": DEHMapInner(Xoi: xoi, xoiCategory: xoi.xoiCategory)
        default:
            Text("error")
                .onAppear { print("[DEBUG] XOIMediaSelector: Unknown xoiCategory \(xoi.xoiCategory)") }
        }
    }
    
    func getViewerNumber() {
        let parameters: Parameters = [
            "poi_id": xoi.id
        ]
        let url = POIClickCountUrl
        let publisher: DataResponsePublisher<ClickCount> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
        self.cancellable = publisher.sink(receiveValue: { (values) in
            if let count = values.value?.count {
                print("[DEBUG] Viewer count for XOI \(xoi.id): \(count)")
                viewNumbers = count
            } else {
                print("[DEBUG] Failed to get viewer count for XOI \(xoi.id): \(values.error?.localizedDescription ?? "No data")")
                viewNumbers = -1
            }
        })
    }
    
    func getMedia() {
        medias = []
        isLoading = true
        print("[DEBUG] getMedia started for XOI \(xoi.id): \(xoi.name)")
        
        if xoi.mediaSet.isEmpty {
            print("[DEBUG] No mediaSet entries for XOI \(xoi.id)")
            medias = [MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture)]
            DispatchQueue.main.async {
                self.isLoading = false
                print("[DEBUG] Set default 'none' image and marked loading complete")
            }
            return
        }
        
        for (index, media) in xoi.mediaSet.enumerated() {
            print("[DEBUG] Processing media item \(index + 1) of \(xoi.mediaSet.count)")
            
            if media.mediaFormat == 0 || media.mediaUrl.isEmpty {
                print("[DEBUG] Skipping invalid media: format=\(media.mediaFormat), url=\(media.mediaUrl)")
                continue
            }
            
            let url = media.mediaUrl
            print("[DEBUG] Fetching media from \(url)")
            
            let publisher: DataResponsePublisher = NetworkConnector().getMediaPublisher(url: url)
            let cancelable = publisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { values in
                    if let data = values.data, !data.isEmpty {
                        print("[DEBUG] Fetched \(data.count) bytes from \(url)")
                        if let mediaFormat = format(rawValue: media.mediaFormat) {
                            switch mediaFormat {
                            case .Commentary:
                                self.commentary = MediaMulti(data: data, format: mediaFormat)
                                print("[DEBUG] Set commentary with format \(mediaFormat.rawValue), size \(data.count) bytes")
                            case .Video, .Voice, .Picture:
                                if mediaFormat == .Picture, UIImage(data: data) == nil {
                                    print("[DEBUG] Invalid image data from \(url)")
                                    self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                                } else {
                                    let mediaItem = MediaMulti(data: data, format: mediaFormat)
                                    self.medias.append(mediaItem)
                                    print("[DEBUG] Added media with format \(mediaFormat.rawValue), size \(data.count) bytes")
                                }
                            case .Default:
                                print("[DEBUG] Default format encountered for \(url)")
                                self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                            }
                        } else {
                            print("[DEBUG] Unknown media format \(media.mediaFormat) for \(url)")
                            self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                        }
                    } else {
                        print("[DEBUG] Failed to fetch media from \(url): \(values.error?.localizedDescription ?? "No data received")")
                        self.medias.append(MediaMulti(data: UIImage(imageLiteralResourceName: "none").pngData() ?? Data(), format: .Picture))
                    }
                    
                    let expectedMediaCount = self.xoi.mediaSet.filter { $0.mediaFormat != 0 && !$0.mediaUrl.isEmpty }.count
                    let currentCount = self.medias.count + (self.commentary != nil ? 1 : 0)
                    
                    if currentCount >= expectedMediaCount {
                        print("[DEBUG] All media items processed, medias count: \(self.medias.count), commentary set: \(self.commentary != nil)")
                        self.isLoading = false
                    }
                })
            
            self.mediaCancellable.append(cancelable)
        }
    }
    
    func navigatedAction() {
        let srcLocation = MKMapItem.forCurrentLocation()
        let dst = CLLocationCoordinate2D(latitude: xoi.latitude, longitude: xoi.longitude)
        let dstLocation = MKMapItem.init(placemark: MKPlacemark(coordinate: dst, addressDictionary: nil))
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        MKMapItem.openMaps(with: [srcLocation, dstLocation], launchOptions: options)
    }
}

// MARK: - Preview Provider (Fixed)
struct XOIDetail_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock XOI instance for preview
        let mockXOI = XOI(
            id: 1,
            name: "Sample POI",
            latitude: 22.997,
            longitude: 120.221,
            creatorCategory: "user",
            xoiCategory: "poi",
            detail: "Sample detail",
            viewNumbers: 0,
            mediaCategory: "image",
            mediaSet: [MediaSet(mediaType: "jpeg", mediaFormat: 1, mediaUrl: "https://example.com/image.jpg")],
            open: true
        )
        
        // Use XOIDetail with the mock XOI and a mock SettingStorage
        XOIDetail(xoi: mockXOI, secondimage: "")
            .environmentObject(SettingStorage.shared)
    }
}
