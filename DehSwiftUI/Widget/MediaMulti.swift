import SwiftUI
import AVKit

enum format: Int {
    case Commentary = 8
    case Video = 4
    case Voice = 2
    case Picture = 1
    case Default = 0
}

class MediaMulti: ObservableObject {
    var mediaFormat: format = .Default
    var data: Data
    var player: AVPlayer?
    @Published var isPlaying: Bool = false
    
    init(data: Data, format: format) {
        self.data = data
        self.mediaFormat = format
        if self.mediaFormat == .Video {
            self.player = AVPlayer(url: dataToUrl(data: data))
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func toggleAudio() {
        if isPlaying {
            // Stop playing the audio
            Sounds.stopAudio()
            
            // Important: Update UI state on main thread
            DispatchQueue.main.async {
                self.isPlaying = false
                print("🔄 Audio state set to not playing")
            }
        } else {
            // Play the audio with completion handler
            let success = Sounds.playAudioWithStateAndCompletion(soundData: self.data) {
                // This will be called when playback completes
                DispatchQueue.main.async {
                    self.isPlaying = false
                    print("✅ Audio playback completed")
                }
            }
            
            // Only update UI if playback started successfully
            if success {
                DispatchQueue.main.async {
                    self.isPlaying = true
                    print("▶️ Audio state set to playing")
                }
            }
        }
    }
    
    // Use this to create a new View that will observe the isPlaying state
    func createView() -> some View {
        MediaView(mediaMulti: self)
    }
    
    @ViewBuilder func view() -> some View {
        switch self.mediaFormat {
        case .Picture:
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(1.2)  // Makes the image 20% bigger
            }
            
        case .Video:
            VideoPlayer(player: player)
            
        case .Voice:
            ZStack {
                // Background image
                Image("audio_picture")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 400)
                
                // Play/pause button overlay with explicit observation of isPlaying
                Button(action: {
                    self.toggleAudio()  // Fixed: explicit self reference
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                // Audio playing indicator
                if isPlaying {
                    VStack {
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 6, height: 30 + CGFloat(i * 5))
                                    .opacity(0.7)
                            }
                        }
                        .offset(y: -40)
                    }
                }
            }
            
        case .Commentary:
            Button(action: {
                self.toggleAudio()  // Fixed: explicit self reference
            }) {
                HStack(spacing: 5) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Text(isPlaying ? "Pause" : "Play")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(20)
            }
            
        default:
            Image("none")
        }
    }
    
    private func dataToUrl(data: Data) -> URL {
        let tmpFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("video")
            .appendingPathExtension("mp4")
        
        try? data.write(to: tmpFileURL, options: [.atomic])
        return tmpFileURL
    }
}

// A dedicated SwiftUI view that properly observes MediaMulti state changes
struct MediaView: View {
    @ObservedObject var mediaMulti: MediaMulti
    
    var body: some View {
        switch mediaMulti.mediaFormat {
        case .Picture:
            if let image = UIImage(data: mediaMulti.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(1.2)  // Makes the image 20% bigger
            }
            
        case .Video:
            VideoPlayer(player: mediaMulti.player)
            
        case .Voice:
            ZStack {
                // Background image
                Image("audio_picture")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 400)
                
                // Play/pause button overlay with explicit observation of isPlaying
                Button(action: {
                    mediaMulti.toggleAudio()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: mediaMulti.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                // Audio playing indicator
                if mediaMulti.isPlaying {
                    VStack {
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 6, height: 30 + CGFloat(i * 5))
                                    .opacity(0.7)
                            }
                        }
                        .offset(y: -40)
                    }
                }
            }
            
        case .Commentary:
            Button(action: {
                mediaMulti.toggleAudio()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: mediaMulti.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Text(mediaMulti.isPlaying ? "Pause" : "Play")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(20)
            }
            
        default:
            Image("none")
        }
    }
}
