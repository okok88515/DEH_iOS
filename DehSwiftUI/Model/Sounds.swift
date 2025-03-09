//
//  Sounds.swift
//  DehSwiftUI
//
//  Created by 阮盟雄 on 2021/1/20.
//  Copyright © 2021 mmlab. All rights reserved.
//

import Foundation
import AVFoundation

class Sounds {
    static var audioPlayer: AVAudioPlayer?
    var audioRecoder: AVAudioRecorder?
    
    // Fixed URL path for consistency
    var tempVideoFileUrl: URL {
        // Create a consistent path with the same name
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "audioanswer.m4a"  // Use m4a which iOS definitely supports
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        print("🔊 Audio file path: \(fileURL.path)")
        return fileURL
    }
    
    static func playSounds(soundfile: String) {
        if let path = Bundle.main.path(forResource: soundfile, ofType: nil) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("❌ Error playing sound file: \(error.localizedDescription)")
            }
        }
    }
    
    static func playSounds(soundData: Data) {
        do {
            print("📊 Audio data size for playback: \(soundData.count) bytes")
            audioPlayer = try AVAudioPlayer(data: soundData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("▶️ Started audio playback")
        } catch {
            print("❌ Error playing sound data: \(error.localizedDescription)")
        }
    }
    
    // New method for controlled audio playback
    static func playAudioWithState(soundData: Data) -> Bool {
        do {
            // Stop any currently playing audio
            audioPlayer?.stop()
            
            print("📊 Audio data size for playback: \(soundData.count) bytes")
            
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: soundData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            print("▶️ Started audio playback")
            return true
        } catch {
            print("❌ Error playing sound data: \(error.localizedDescription)")
            return false
        }
    }
    
    // New method to stop audio playback
    static func stopAudio() {
        audioPlayer?.stop()
        print("⏹️ Stopped audio playback")
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ Error resetting audio session: \(error.localizedDescription)")
        }
    }
    
    // New method to check if audio is playing
    static func isAudioPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func recordSounds() {
        // Use AAC format which is definitely supported by iOS
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),  // AAC encoding is well-supported
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey: 96000  // Good quality, medium file size
        ]
        
        do {
            // Setup audio session properly
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Print temporary directory to debug
            print("📂 Temp directory: \(FileManager.default.temporaryDirectory.path)")
            
            // Make sure the directory exists and is writable
            let directoryPath = tempVideoFileUrl.deletingLastPathComponent().path
            var isDir: ObjCBool = false
            if !FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDir) {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
                print("📁 Created directory: \(directoryPath)")
            }
            
            // Delete any existing file at the path
            if FileManager.default.fileExists(atPath: tempVideoFileUrl.path) {
                try FileManager.default.removeItem(at: tempVideoFileUrl)
                print("🗑️ Removed existing audio file")
            }
            
            // Create and start recorder
            audioRecoder = try AVAudioRecorder(url: tempVideoFileUrl, settings: settings)
            if audioRecoder != nil {
                audioRecoder?.prepareToRecord()
                let recordingStarted = audioRecoder?.record() ?? false
                print("🎙️ Started recording to: \(tempVideoFileUrl.path), success: \(recordingStarted)")
            } else {
                print("❌ Failed to create audio recorder")
            }
        } catch {
            print("❌ Error setting up audio recorder: \(error.localizedDescription)")
        }
    }
    
    func stopRecord() {
        print("⏹️ Stopping recording")
        audioRecoder?.stop()
        
        // Check if file was created
        if FileManager.default.fileExists(atPath: tempVideoFileUrl.path) {
            print("✅ Audio file created at: \(tempVideoFileUrl.path)")
            
            // Try to get file attributes to log size
            if let attrs = try? FileManager.default.attributesOfItem(atPath: tempVideoFileUrl.path),
               let size = attrs[.size] as? UInt64 {
                print("📊 Audio file size: \(size) bytes")
            }
        } else {
            print("❌ No audio file found after recording at: \(tempVideoFileUrl.path)")
            
            // List all files in temp directory for debugging
            if let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path) {
                print("Files in temp directory:")
                for file in files {
                    print("- \(file)")
                }
            }
        }
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Error resetting audio session: \(error.localizedDescription)")
        }
    }
}
// Audio Player Delegate to handle playback completion
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onCompletion: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            onCompletion?()
        }
    }
}

// Improve Sounds class with audio completion handling
extension Sounds {
    // Singleton delegate instance to be reused
    private static var audioDelegate = AudioPlayerDelegate()
    
    // Enhanced version of playAudioWithState that supports completion callback
    static func playAudioWithStateAndCompletion(soundData: Data, onCompletion: @escaping () -> Void) -> Bool {
        do {
            // Stop any currently playing audio
            audioPlayer?.stop()
            
            print("📊 Audio data size for playback: \(soundData.count) bytes")
            
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: soundData)
            
            // Set up completion handler
            audioDelegate.onCompletion = onCompletion
            audioPlayer?.delegate = audioDelegate
            
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            print("▶️ Started audio playback with completion handler")
            return true
        } catch {
            print("❌ Error playing sound data: \(error.localizedDescription)")
            return false
        }
    }
}
