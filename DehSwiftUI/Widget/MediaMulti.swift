import SwiftUI
import AVKit

enum format: Int {
    case Commentary = 8
    case Video = 4
    case Voice = 2
    case Picture = 1
    case Default = 0
}

class MediaMulti {
    var mediaFormat: format = .Default
    var data: Data
    var player: AVPlayer?
    
    init(data: Data, format: format) {
        self.data = data
        self.mediaFormat = format
        if self.mediaFormat == .Video {
            self.player = AVPlayer(url: dataToUrl(data: data))
        }
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
            Button(action: {
                Sounds.playSounds(soundData: self.data)
            }) {
                Image("audio_picture")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 400)
            }
        case .Commentary:
            Button(action: {
                Sounds.playSounds(soundData: self.data)
            }) {
                Image("audio_button")
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
