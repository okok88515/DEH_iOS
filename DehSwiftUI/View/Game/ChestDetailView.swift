import SwiftUI
import Combine
import Alamofire
import AVFoundation
import AVKit

struct ChestMedia: Decodable {
    var id: Int
    var url: URL
    var format: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ATT_id"
        case url = "ATT_url"
        case format = "ATT_format"
    }
}

// Helper extension for Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct AudioRecordView: View {
    @Binding var audioURL: URL?
    @Binding var recorder: Sounds?
    @Environment(\.presentationMode) var presentationMode
    @State private var isRecording = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        VStack(spacing: 40) {
            Text("Record Your Answer")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 20)
            
            VStack {
                Button(action: {
                    if isRecording {
                        recorder?.stopRecord()
                        audioURL = recorder?.tempVideoFileUrl
                        isRecording = false
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        AVAudioSession.sharedInstance().requestRecordPermission { granted in
                            DispatchQueue.main.async {
                                if granted {
                                    recorder = Sounds()
                                    recorder?.recordSounds()
                                    isRecording = true
                                } else {
                                    showPermissionDeniedAlert = true
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(isRecording ? .red : .blue)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                
                Text(isRecording ? "Recording in Progress..." : "Press to Start Recording")
                    .foregroundColor(.secondary)
                    .font(.headline)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(15)
        .padding()
        .alert(isPresented: $showPermissionDeniedAlert) {
            Alert(
                title: Text("Microphone Access Denied"),
                message: Text("Please enable microphone access in Settings to record audio."),
                primaryButton: .default(Text("Open Settings"), action: {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
}



struct ChestDetailView: View {
    @ObservedObject var locationManager = LocationManager()
    @EnvironmentObject var settingStorage: SettingStorage
    @StateObject var gameVM: GameViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var playVideo = false
    @State private var chestCancellable: AnyCancellable?
    @State private var minusCancellable: AnyCancellable?
    @State private var mediaCancellable: [AnyCancellable] = []
    @State private var uploadMediaCancellable: AnyCancellable?
    @State var chest: ChestModel
    @State var session: SessionModel
    @State var chestMedia: [ChestMedia] = []
    @State var medias: [MediaMulti] = []
    @State var index = 0
    @State var answer = ""
    @State var showMessage = false
    @State var responseMessage: String = ""
    @State var textInEditor = ""
    @State var selection: Int? = nil
    @State var mediaData: Data? = nil
    @State var recoder: Sounds? = nil

    // Multimedia answer states
    @State private var image = UIImage()
    @State private var isShowPhotoLibrary = false
    @State private var showAudioRecorder = false
    @State private var audioURL: URL?
    @State private var answerType: AnswerType = .text

    enum AnswerType {
        case text, image, audio
    }

    var body: some View {
        ZStack {
            Color.init(UIColor.systemGray5)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack(spacing: 20) {
                    PagingView(index: $index.animation(), maxIndex: medias.count - 1) {
                        ForEach(self.medias, id: \.data) { singleMedia in
                            singleMedia.view()
                        }
                    }
                    .frame(height: geometry.size.height * 0.4)

                    ScrollView {
                        HStack {
                            Spacer()
                            Text("Question:")
                                .multilineTextAlignment(.center)
                                .frame(height: geometry.size.height * 0.03)
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Done")
                                    .font(.headline)
                            }
                        }
                        Divider()
                        Text(chest.question)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.15)

                        answerBoxSelector(chest.questionType, geometry)
                            .alert(isPresented: $showMessage) {
                                Alert(
                                    title: Text(responseMessage),
                                    dismissButton: .default(Text("Ok"), action: {
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                )
                            }
                        Spacer()
                    }
                }
                .padding()
                .onAppear {
                    getChestMedia()
                }
                .sheet(isPresented: $isShowPhotoLibrary) {
                    ImagePicker(selectedImage: $image, mediaData: $mediaData, sourceType: .photoLibrary)
                }
                .sheet(isPresented: $showAudioRecorder) {
                    AudioRecordView(audioURL: $audioURL, recorder: $recoder)
                }
            }
            EmptyView()
        }
        .onTapGesture {
            self.hideKeyboard()
        }
    }
}

// MARK: - View Extensions
extension ChestDetailView {
    @ViewBuilder func answerBoxSelector(_ questionType: Int, _ geometry: GeometryProxy? = nil) -> some View {
        switch questionType {
        case 1: // True/False
            HStack {
                Button(action: { checkAnswer("T") }) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                Button(action: { checkAnswer("F") }) {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
            }
            .padding()
        
        case 2: // Multiple Choice
            VStack {
                HStack {
                    buttonViewer(answer: "A", option: chest.option1 ?? "")
                    buttonViewer(answer: "B", option: chest.option2 ?? "")
                }
                HStack {
                    buttonViewer(answer: "C", option: chest.option3 ?? "")
                    buttonViewer(answer: "D", option: chest.option4 ?? "")
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
        
        case 3: // Essay/Media Question
            VStack {
                Menu {
                    Button("Text") {
                        answerType = .text
                    }
                    Button("Image") {
                        answerType = .image
                    }
                    Button("Audio") {
                        answerType = .audio
                    }
                } label: {
                    HStack {
                        Text("\("Answer Type".localized): \(answerType == .text ? "Text".localized : answerType == .image ? "Image".localized : "Audio".localized)")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)

                switch answerType {
                case .text:
                    ZStack(alignment: .leading) {
                        if textInEditor.isEmpty {
                            Text("Please enter here")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                        }
                        TextEditor(text: $textInEditor)
                            .padding(8)
                            .frame(height: (geometry?.size.height ?? 0) * 0.2)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                
                case .image:
                    VStack {
                        if let media = mediaData.flatMap({ data in MediaMulti(data: data, format: .Picture) }) {
                            media.view()
                                .frame(height: 200)
                        } else {
                            Image(uiImage: self.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            self.isShowPhotoLibrary = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                Text("Choose Photo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                    }
                
                case .audio:
                    VStack {
                        if let url = audioURL {
                            if let audioData = try? Data(contentsOf: url) {
                                let media = MediaMulti(data: audioData, format: .Voice)
                                media.view()
                            }
                        }
                        Button(audioURL == nil ? "Record Audio" : "Re-record Audio") {
                            showAudioRecorder = true
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                }
                
                Button(action: {
                    if answerType == .text {
                        checkAnswer(textInEditor)
                        insertAnswer(answer: textInEditor, correctness: "\(self.chest.answer == textInEditor ? "1" : "0")")
                    } else {
                        submitMultimediaAnswer()
                    }
                }) {
                    Text("Submit Answer")
                        .font(.headline)
                        .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.top)
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder func buttonViewer(answer: String, option: String) -> some View {
        Button(action: { checkAnswer(answer) }) {
            Text(option)
                .fontWeight(.bold)
                .font(.title)
                .frame(minWidth: 100, minHeight: 100)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.init(UIColor(rgba: lightGreen)), lineWidth: 5)
                )
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                .padding()
        }
    }
}


extension ChestDetailView {
    func getChestMedia() {
        let url = getChestMediaUrl
        let parameters: [String:String] = [
            "chest_id": "\(chest.id)",
        ]
        let publisher: DataResponsePublisher<[ChestMedia]> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.chestCancellable = publisher
            .sink(receiveValue: {(values) in
                if let value = values.value {
                    self.chestMedia = value
                }
                for chestMedia in self.chestMedia {
                    let publisher: DataResponsePublisher = NetworkConnector().getMediaPublisher(url: chestMedia.url)
                    let cancelable = publisher
                        .sink(receiveValue: {(values) in
                            if let data = values.data {
                                medias.append(MediaMulti(data:data, format:.Picture))
                            }
                        })
                    self.mediaCancellable.append(cancelable)
                }
            })
    }
    
    func submitMultimediaAnswer() {
        let parameters: [String: String] = [
            "user_id": "\(settingStorage.userID)",
            "chest_id": "\(chest.id)",
            "game_id": "\(session.gameID)",
            "lat": "\(locationManager.coordinateRegion.center.latitude)",
            "lng": "\(locationManager.coordinateRegion.center.longitude)",
            "point": "\(chest.point ?? 0)",
            "txt": textInEditor
        ]
        
        var inputData: Data?
        var mimeType: String = ""
        
        switch answerType {
        case .image:
            if let imageData = mediaData {
                inputData = imageData
                mimeType = "image/jpeg"
            } else if let jpegData = image.jpegData(compressionQuality: 0.8) {
                inputData = jpegData
                mimeType = "image/jpeg"
            }
        case .audio:
            if let audioURL = audioURL {
                inputData = try? Data(contentsOf: audioURL)
                mimeType = "audio/m4a"
            }
        case .text:
            inputData = textInEditor.data(using: .utf8)
            mimeType = "text/plain"
        }
        
        guard let uploadData = inputData else {
            responseMessage = "No data to upload"
            showMessage = true
            return
        }
        
        // Debug prints
        print("Uploading with parameters:", parameters)
        print("MIME Type:", mimeType)
        print("Upload Data Size:", uploadData.count)
        
        let url = uploadMediaAnswerUrl
        
        AF.upload(multipartFormData: { multipartFormData in
            // Add parameters
            for (key, value) in parameters {
                multipartFormData.append(Data(value.utf8), withName: key)
            }
            
            // Add file with the correct field name
            multipartFormData.append(uploadData,
                                   withName: "data",  // Match the field name expected by the server
                                   fileName: "file.\(mimeType.split(separator: "/")[1])",
                                   mimeType: mimeType)
        }, to: url)
        .validate()
        .response { response in  // Changed from responseDecodable to response
            print("Full Response:", response.debugDescription)
            
            DispatchQueue.main.async {
                // Consider 200 status code as success, regardless of response body
                if response.response?.statusCode == 200 {
                    if let index = self.gameVM.chestList.firstIndex(of: self.chest) {
                        self.gameVM.chestList.remove(at: index)
                    }
                    self.responseMessage = "Answer submitted successfully"
                    self.showMessage = true
                } else {
                    print("Upload failed with status code:", response.response?.statusCode ?? -1)
                    if let data = response.data, let errorStr = String(data: data, encoding: .utf8) {
                        print("Error response:", errorStr)
                    }
                    self.responseMessage = "Failed to submit answer"
                    self.showMessage = true
                }
            }
        }
    }


    
    func checkAnswer(_ answer: String) {
        if(answer == "T" || answer == "F" ) {
            if(self.chest.answer == answer) {
                responseMessage = "answer correct"
                let points = chest.point ?? 0
                gameVM.score += points
                gameVM.updateScore(userID: self.settingStorage.userID, session: session)
                print("game score: \(gameVM.score)")
            } else if(self.chest.answer != answer) {
                responseMessage = "answer wrong"
            }
        } else if (answer == "A" || answer == "B" || answer == "C" || answer == "D" ) {
            if(self.chest.answer == answer) {
                responseMessage = "answer correct"
                let points = chest.point ?? 0
                gameVM.score += points
                gameVM.updateScore(userID: self.settingStorage.userID, session: session)
                print("game score: \(gameVM.score)")
            } else if(self.chest.answer != answer) {
                responseMessage = "answer wrong"
            }
        } else {  //問答題
            if(self.chest.answer == answer) {
                responseMessage = "answer correct"
                let points = chest.point ?? 0
                gameVM.score += points
                gameVM.updateScore(userID: self.settingStorage.userID, session: session)
                print("game score: \(gameVM.score)")
            } else if(self.chest.answer != answer) {
                responseMessage = "answer wrong"
            }
        }
        showMessage = true
        chestMinus(answer: answer, correctness: "\(self.chest.answer == answer ? "1" : "0")")
    }
    
    func insertAnswer(answer: String, correctness: String) {
            let url = insertAnswerUrl
            let parameters: [String:String] = [
                "user_id": "\(settingStorage.userID)",
                "game_id": "\(session.gameID)",
                "chest_id": "\(chest.id)",
                "answer": answer,
                "point": "\(String(describing: chest.point ?? 0))",
                "correctness": correctness,
                "lat": String(describing: locationManager.coordinateRegion.center.latitude),
                "lng": String(describing: locationManager.coordinateRegion.center.longitude),
            ]
            
            let publisher: DataResponsePublisher<String> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
            self.chestCancellable = publisher
                .sink(receiveValue: { values in
                    if answer == self.chest.answer {
                        self.responseMessage = "answer correct"
                        self.gameVM.score += self.chest.point ?? 0
                    } else {
                        self.responseMessage = "answer wrong"
                    }
                    self.showMessage = true
                })
        }
    func chestMinus(answer: String, correctness: String) {
        let url = chestMinusUrl
        let parameters: [String: Any] = [
            "userId": settingStorage.userID,
            "gameId": session.gameID,
            "chestId": chest.id,
            "userAnswer": answer,
            "latitude": locationManager.coordinateRegion.center.latitude,
            "longitude": locationManager.coordinateRegion.center.longitude
        ]
        
        print("=== ChestMinus API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        // Update response type to match backend structure
        struct ChestResponse: Decodable {
            let results: MessageResponse
            
            struct MessageResponse: Decodable {
                let message: String
            }
        }
        
        let publisher: DataResponsePublisher<ChestResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters)
        self.minusCancellable = publisher
            .sink(receiveValue: { values in
                print("\n=== ChestMinus Response ===")
                if let statusCode = values.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                }
                
                // Print raw response data
                if let data = values.data, let rawString = String(data: data, encoding: .utf8) {
                    print("Raw Response Data:", rawString)
                }
                
                if let error = values.error {
                    print("Error:", error)
                    return
                }
                
                if let message = values.value?.results.message {
                    print("Server Response:", message)
                    
                    // Handle different response cases
                    switch message {
                    case "finish":
                        print("Answer submitted successfully")
                    case "chest is empty":
                        print("Chest is already empty")
                    case "already answer":
                        print("Already answered this chest")
                    case let msg where msg.contains("server sql error"):
                        print("Server error occurred:", msg)
                    default:
                        print("Unexpected response:", message)
                    }
                }
                
                print("=== ChestMinus Completed ===\n")
            })
        
        print("API request initiated")
    }
   }


