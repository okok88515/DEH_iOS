import SwiftUI
import Combine
import Alamofire
import AVFoundation
import AVKit


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
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showPermissionDeniedAlert = false
    @State private var playbackError: String? = nil
    @State private var fileExists: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Record Your Answer")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 20)
            
            // Recording indicator
            if isRecording {
                Text(timeString(from: recordingDuration))
                    .font(.system(size: 28, design: .monospaced))
                    .foregroundColor(.red)
                    .padding()
                
                // Animated recording indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .opacity(recordingDuration.truncatingRemainder(dividingBy: 1.0) < 0.5 ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.5), value: recordingDuration)
            }
            
            // Main record button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 100, height: 100)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 20)
            
            Text(isRecording ? "Recording in Progress..." : "Press to Start Recording")
                .foregroundColor(.secondary)
                .font(.headline)
            
            // Show error message if playback failed
            if let error = playbackError {
                Text("Playback error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            // Playback controls (visible only after recording)
            if !isRecording && audioURL != nil {
                // Show if file exists
                if fileExists {
                    Text("Recording saved successfully")
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.bottom, 8)
                    
                    Button(action: {
                        playRecording()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18))
                            Text("Play Recording")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Recording failed to save properly")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 8)
                    
                    Button(action: {
                        startRecording()
                    }) {
                        Text("Try Recording Again")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text(fileExists ? "Use This Recording" : "Continue Without Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(fileExists ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
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
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // Start recording with permission check
    private func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.recorder = Sounds()
                    self.recorder?.recordSounds()
                    self.isRecording = true
                    self.recordingDuration = 0
                    self.playbackError = nil
                    self.fileExists = false
                    
                    // Start timer to track recording duration
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        self.recordingDuration += 0.1
                    }
                } else {
                    self.showPermissionDeniedAlert = true
                }
            }
        }
    }
    
    // Stop recording and save file
    private func stopRecording() {
        recorder?.stopRecord()
        audioURL = recorder?.tempVideoFileUrl
        isRecording = false
        timer?.invalidate()
        
        // Check if file exists
        if let url = audioURL {
            fileExists = FileManager.default.fileExists(atPath: url.path)
            print("📂 Audio saved to: \(url.path), exists: \(fileExists)")
            
            if fileExists {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? UInt64 {
                    print("📊 Size: \(size) bytes")
                }
            } else {
                print("❌ File does not exist at path: \(url.path)")
            }
        }
    }
    
    // Safely play the recording
    private func playRecording() {
        guard let url = audioURL else {
            playbackError = "No audio URL"
            return
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            playbackError = "File not found at \(url.lastPathComponent)"
            print("❌ Error: Audio file not found at \(url.path)")
            return
        }
        
        do {
            let audioData = try Data(contentsOf: url)
            print("📢 Playing audio data of size: \(audioData.count) bytes")
            
            // Try to play the audio
            Sounds.playSounds(soundData: audioData)
            playbackError = nil
        } catch {
            playbackError = error.localizedDescription
            print("❌ Error playing audio: \(error.localizedDescription)")
        }
    }
    
    // Format time interval for display
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let tenths = Int((timeInterval - floor(timeInterval)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
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
                ScrollView {
                    VStack(spacing: 5) {
                        // Header - Moved to absolute top
                        HStack {
                            Text("Question:")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Done")
                                    .font(.headline)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        
                        Divider()
                            .padding(.horizontal)

                        // Problem Box - Increased size by 20%
                        ScrollView {
                            Text(chest.question)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.3) // Increased by 20%
                        .padding(.horizontal)

                        // Media viewer section - if needed
                        if !medias.isEmpty {
                            PagingView(index: $index.animation(), maxIndex: medias.count - 1) {
                                ForEach(self.medias, id: \.data) { singleMedia in
                                    singleMedia.view()
                                        .frame(height: geometry.size.height * 0.3)  // Increased from 0.25 to 0.3 (20% bigger)
                                }
                            }
                            .frame(height: geometry.size.height * 0.3)  // Match the content height
                        }

                        // Answer Box - Moved up with ScrollView for long content
                        ScrollView {
                            answerBoxSelector(chest.questionType, geometry)
                                .padding(.horizontal)
                                .alert(isPresented: $showMessage) {
                                    Alert(
                                        title: Text(responseMessage),
                                        dismissButton: .default(Text("Ok"), action: {
                                            self.presentationMode.wrappedValue.dismiss()
                                        })
                                    )
                                }
                        }
                        .frame(minHeight: geometry.size.height * 0.4) // Ensure enough space for answers
                    }
                }
                .onAppear {
                    loadChestMedia()
                }
                .sheet(isPresented: $isShowPhotoLibrary) {
                    ImagePicker(selectedImage: $image, mediaData: $mediaData, sourceType: .photoLibrary)
                }
                .sheet(isPresented: $showAudioRecorder) {
                    AudioRecordView(audioURL: $audioURL, recorder: $recoder)
                }
            }
        }
        .onTapGesture {
            self.hideKeyboard()
        }
    }
}

// MARK: - View Extensions
extension ChestDetailView {
    @ViewBuilder func buttonViewer(answer: String, option: String) -> some View {
        Button(action: { checkAnswer(answer) }) {
            Text(option)
                .fontWeight(.bold)
                .font(.title3)
                .padding(12)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.init(UIColor(rgba: lightGreen)), lineWidth: 5)
                )
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.vertical, 3)
    }
    @ViewBuilder func answerBoxSelector(_ questionType: Int, _ geometry: GeometryProxy) -> some View {
        switch questionType {
        case 1: // True/False
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.3) // Push content down more
                
                VStack(spacing: 15) {
                    Text("選擇你的答案:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 40) {
                        VStack(spacing: 5) {
                            Button(action: { checkAnswer("T") }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.green)
                            }
                            Text("True")
                                .font(.callout)
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 5) {
                            Button(action: { checkAnswer("F") }) {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.red)
                            }
                            Text("False")
                                .font(.callout)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                }
                
                Spacer() // Keep some space at bottom
            }
        
        case 2: // Multiple Choice
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    buttonViewer(answer: "A", option: chest.option1 ?? "")
                    buttonViewer(answer: "B", option: chest.option2 ?? "")
                }
                HStack(spacing: 8) {
                    buttonViewer(answer: "C", option: chest.option3 ?? "")
                    buttonViewer(answer: "D", option: chest.option4 ?? "")
                }
            }
            .padding(.vertical, 8)
        
        
        case 3: // Essay/Media Question
            VStack {
                Menu {
                    Button("文字") {
                        answerType = .text
                    }
                    Button("文字 + 圖片") {
                        answerType = .image
                    }
                    Button("文字 + 語音") {
                        answerType = .audio
                    }
                } label: {
                    HStack {
                        Text("\("Answer Type".localized): \(answerType == .text ? "文字" : answerType == .image ? "文字 ＋ 圖片" : "文字 ＋ 語音")")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Text input always visible regardless of answer type
                ZStack(alignment: .leading) {
                    if textInEditor.isEmpty {
                        Text("Please enter your text answer here")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                    }
                    TextEditor(text: $textInEditor)
                        .padding(8)
                        .frame(height: geometry.size.height * 0.15)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)

                // Conditional display of media inputs based on answer type
                if answerType == .image {
                    VStack {
                        if let media = mediaData.flatMap({ data in MediaMulti(data: data, format: .Picture) }) {
                            media.view()
                                .frame(height: 150)
                        } else {
                            Image(uiImage: self.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
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
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                } else if answerType == .audio {
                    VStack {
                        if let url = audioURL {
                            if let audioData = try? Data(contentsOf: url) {
                                let media = MediaMulti(data: audioData, format: .Voice)
                                media.view()
                                    .frame(height: 100)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        } else {
                            // Placeholder when no audio is recorded
                            VStack {
                                Image(systemName: "waveform")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No audio recorded")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(audioURL == nil ? "Record Audio" : "Re-record Audio") {
                            showAudioRecorder = true
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    if answerType == .text {
                        // No longer checking if answer is correct, just submitting to backend
                        chestMinus(answer: textInEditor, correctness: "1")
                        
                        // Remove the chest from the list
                        if let index = self.gameVM.chestList.firstIndex(of: self.chest) {
                            self.gameVM.chestList.remove(at: index)
                        }
                        
                        // Update game score
                        let points = self.chest.point ?? 0
                        self.gameVM.score += points
                        self.gameVM.updateScore(userID: self.settingStorage.userID, session: self.session)
                        
                        responseMessage = "Answer submitted successfully"
                        showMessage = true
                    } else {
                        submitMultimediaAnswer()
                    }
                }) {
                    Text("Submit Answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
        default:
            EmptyView()
        }
    }
}

extension ChestDetailView {
    // this one has problem and claude use loadChestMedia to replace
    func getChestMedia() {
        let url = getChestMediaUrl
        let parameters: [String:String] = [
            "chest_id": "\(chest.id)",
        ]
        
        print("=== GetChestMedia API Call ===")
        print("URL:", url)
        print("Parameters:", parameters)
        
        let publisher: DataResponsePublisher<[ChestMedia]> = NetworkConnector().getDataPublisherDecodable(
            url: url,
            para: parameters,
            addLogs: true
        )
        
        self.chestCancellable = publisher
            .sink(receiveValue: { values in
                // Print raw response for debugging
                if let data = values.data {
                    print("Raw response:", String(data: data, encoding: .utf8) ?? "No data")
                }
                
                if let error = values.error {
                    print("Error fetching chest media:", error)
                    return
                }
                
                if let mediaList = values.value {
                    print("Received \(mediaList.count) media items")
                    self.chestMedia = mediaList
                    
                    // Clear existing media
                    self.medias.removeAll()
                    self.mediaCancellable.removeAll()
                    
                    // Load each media item
                    for media in mediaList {
                        print("Loading media: format \(media.mediaFormat) from \(media.mediaUrl)")
                        guard let mediaURL = media.url else {
                            print("Invalid media URL:", media.mediaUrl)
                            continue
                        }
                        
                        let publisher: DataResponsePublisher = NetworkConnector().getMediaPublisher(url: mediaURL)
                        
                        let cancelable = publisher
                            .sink(receiveValue: { values in
                                if let data = values.data {
                                    DispatchQueue.main.async {
                                        self.medias.append(MediaMulti(data: data, format: media.mediaType))
                                    }
                                } else {
                                    print("Failed to load media data")
                                }
                            })
                        
                        self.mediaCancellable.append(cancelable)
                    }
                } else {
                    print("No media found for chest")
                }
            })
    }
    
    func submitMultimediaAnswer() {
        // Create the parameters object
        let parametersDict: [String: Any] = [
            "userId": settingStorage.userID,
            "chestId": chest.id,
            "gameId": session.gameID,
            "userAnswer": textInEditor, // Use text input for all answer types
            "latitude": locationManager.coordinateRegion.center.latitude,
            "longitude": locationManager.coordinateRegion.center.longitude
        ]
        
        // Convert the parameters to a JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parametersDict),
              let paramsString = String(data: jsonData, encoding: .utf8) else {
            responseMessage = "Failed to create request parameters"
            showMessage = true
            return
        }
        
        print("=== Submitting Multimedia Answer ===")
        print("Parameters:", parametersDict)
        
        // Prepare media data based on answer type
        var mediaData: Data?
        var mimeType: String = ""
        var fileExtension: String = ""
        
        switch answerType {
        case .image:
            if let imgData = self.mediaData {
                mediaData = imgData
                mimeType = "image/png"
                fileExtension = "png"
            } else if let pngData = image.pngData() {
                mediaData = pngData
                mimeType = "image/png"
                fileExtension = "png"
            } else {
                responseMessage = "No image selected"
                showMessage = true
                return
            }
            
        case .audio:
            if let url = audioURL {
                // Verify the file exists
                if FileManager.default.fileExists(atPath: url.path) {
                    do {
                        mediaData = try Data(contentsOf: url)
                        
                        // Use M4A format but tell the server it's MP3 for compatibility
                        mimeType = "audio/mpeg"  // Standard MP3 MIME type
                        fileExtension = "mp3"    // Use MP3 extension for Windows
                        
                        print("📁 Audio file size for upload: \(mediaData?.count ?? 0) bytes")
                    } catch {
                        print("❌ Error reading audio file: \(error)")
                        responseMessage = "Error reading audio: \(error.localizedDescription)"
                        showMessage = true
                        return
                    }
                } else {
                    print("❌ Audio file not found at: \(url.path)")
                    responseMessage = "Audio file not found"
                    showMessage = true
                    return
                }
            } else {
                responseMessage = "No audio recorded"
                showMessage = true
                return
            }
            
        case .text:
            // This case should no longer reach here as it's handled directly in the button action
            return
        }
        
        // Make sure we have media data
        guard let uploadData = mediaData else {
            responseMessage = "No media data to upload"
            showMessage = true
            return
        }
        
        // IMPORTANT: Call chestMinus first to register the answer with the backend
        // This ensures the answer is registered even if media upload fails
        chestMinus(answer: textInEditor, correctness: "1") // Always pass 1 for correctness
        
        // Create the multipart request to match your backend
        let url = uploadMediaAnswerUrl
        
        print("🚀 Uploading \(fileExtension) file with MIME type: \(mimeType)")
        print("📊 File size: \(uploadData.count) bytes")
        
        AF.upload(multipartFormData: { multipartFormData in
            // Add the params JSON string
            multipartFormData.append(paramsString.data(using: .utf8)!, withName: "params")
            
            // Add the file with field name 'data' as expected by your backend
            multipartFormData.append(uploadData,
                                    withName: "data",
                                    fileName: "file.\(fileExtension)",
                                    mimeType: mimeType)
            
        }, to: url)
        .uploadProgress { progress in
            print("📤 Upload progress: \(Int(progress.fractionCompleted * 100))%")
        }
        .validate()
        .response { response in
            print("📥 Upload Response Status: \(response.response?.statusCode ?? -1)")
            
            if let data = response.data, let rawString = String(data: data, encoding: .utf8) {
                print("📄 Response: \(rawString)")
            }
            
            DispatchQueue.main.async {
                if response.response?.statusCode == 200 {
                    // Remove the chest from the list
                    if let index = self.gameVM.chestList.firstIndex(of: self.chest) {
                        self.gameVM.chestList.remove(at: index)
                    }
                    
                    // Update game score
                    let points = self.chest.point ?? 0
                    self.gameVM.score += points
                    self.gameVM.updateScore(userID: self.settingStorage.userID, session: self.session)
                    
                    self.responseMessage = "Answer submitted successfully"
                    self.showMessage = true
                } else {
                    self.responseMessage = "Media upload failed, but answer was registered"
                    self.showMessage = true
                }
            }
        }
    }

    // All the points are given from backend by the getUserPoint url, not calculated in this view like before. So ignore all the point calculation related code in this view.
    // The points are calculated and stored on the backend server
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
    //this is useless now
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
            
            let publisher: DataResponsePublisher<String> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
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
    // the corretness passed into chestMinus is useless, backend will compare user answer and correct answer again to determine if user can get points
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
        
        let publisher: DataResponsePublisher<ChestResponse> = NetworkConnector().getDataPublisherDecodable(url: url, para: parameters, addLogs: true)
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


extension ChestDetailView {
    func loadChestMedia() {
        // Clear existing media
        self.medias.removeAll()
        self.mediaCancellable.removeAll()
        
        // Use media directly from the chest model
        if let mediaList = chest.medias {
            print("Found \(mediaList.count) media items in chest")
            
            for media in mediaList {
                print("Loading media: format \(media.mediaFormat) from \(media.mediaUrl)")
                guard let mediaURL = media.url else {
                    print("Invalid media URL:", media.mediaUrl)
                    continue
                }
                
                let publisher: DataResponsePublisher = NetworkConnector().getMediaPublisher(url: mediaURL)
                
                let cancelable = publisher
                    .sink(receiveValue: { values in
                        if let data = values.data {
                            print("Successfully loaded media data of size:", data.count)
                            DispatchQueue.main.async {
                                self.medias.append(MediaMulti(data: data, format: media.mediaType))
                                print("Added media to view, total count:", self.medias.count)
                            }
                        } else {
                            print("Failed to load media data")
                        }
                    })
                
                self.mediaCancellable.append(cancelable)
            }
        } else {
            print("No media found in chest")
        }
    }
}
