//
//  AudioDecoder.swift
//  TiWaveform
//
//  Handles decoding of various audio formats
//

import AVFoundation

public enum AudioFormat {
    case aac
    case mp3
    case wav
    case m4a
    case opus
    case ogg
    case unknown
    
    static func from(url: URL) -> AudioFormat {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "aac": return .aac
        case "mp3": return .mp3
        case "wav": return .wav
        case "m4a": return .m4a
        case "opus": return .opus
        case "ogg": return .ogg
        default: return .unknown
        }
    }
}

/// Unified audio decoder that handles multiple formats
public class AudioDecoder {
    
    // MARK: - Public Methods
    
    /// Decode audio file to PCM buffer
    /// - Parameter url: Audio file URL
    /// - Returns: PCM buffer with decoded audio
    public static func decode(url: URL) throws -> AVAudioPCMBuffer {
        let format = AudioFormat.from(url: url)
        
        switch format {
        case .opus, .ogg:
            // Use OPUS decoder for OPUS/OGG files
            return try decodeOpus(url: url)
            
        case .aac, .mp3, .wav, .m4a:
            // Use AVFoundation for standard formats
            return try decodeWithAVFoundation(url: url)
            
        case .unknown:
            // Try AVFoundation first, fall back to OPUS
            do {
                return try decodeWithAVFoundation(url: url)
            } catch {
                return try decodeOpus(url: url)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Decode using AVFoundation (AAC, MP3, WAV, M4A)
    private static func decodeWithAVFoundation(url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw SamplingError.invalidBuffer
        }
        
        try file.read(into: buffer)
        
        return buffer
    }
    
    /// Decode OPUS/OGG files
    /// Note: This requires libopus integration
    private static func decodeOpus(url: URL) throws -> AVAudioPCMBuffer {
        // This is a placeholder - actual implementation would use OpusDecoder
        // For now, we'll throw an error indicating OPUS support is not yet implemented
        throw SamplingError.unsupportedFormat
        
        // Future implementation:
        // let decoder = OpusDecoder()
        // return try decoder.decode(url: url)
    }
}
