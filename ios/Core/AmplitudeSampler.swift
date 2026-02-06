//
//  AmplitudeSampler.swift
//  TiWaveform
//
//  Extracts amplitude samples from audio files and live recording
//

import AVFoundation
import Accelerate

public enum SamplingError: Error {
    case fileNotFound
    case unsupportedFormat
    case decodingFailed
    case invalidBuffer
    case bufferCreationFailed
}

public enum SamplingMode {
    case playback(targetSamples: Int)
    case recording(windowSize: Int)
}

/// Responsible for extracting amplitude data from audio sources
public class AmplitudeSampler {
    
    // MARK: - Properties
    
    private let mode: SamplingMode
    private var audioFile: AVAudioFile?
    private var audioFormat: AVAudioFormat?
    
    // MARK: - Initialization
    
    public init(mode: SamplingMode) {
        self.mode = mode
    }
    
    // MARK: - Public Methods
    
    /// Sample amplitudes from an audio file
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - targetSamples: Number of samples to extract (default from mode)
    /// - Returns: Array of normalized amplitudes (0.0 to 1.0)
    public func sampleFile(at url: URL, targetSamples: Int? = nil) throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SamplingError.fileNotFound
        }
        
        // Criar buffer (suporta OPUS automaticamente!)
        let buffer = try createBuffer(from: url)
        
        // Determine target sample count
        let samples: Int
        if let targetSamples = targetSamples {
            samples = targetSamples
        } else if case .playback(let target) = mode {
            samples = target
        } else {
            samples = 200 // Default
        }
        
        // Extract and downsample amplitudes
        return try extractAmplitudes(from: buffer, targetSamples: samples)
    }
    
    /// Process live audio buffer (for recording)
    /// - Parameter buffer: Audio buffer from microphone
    /// - Returns: Array of amplitudes
    public func processLiveBuffer(_ buffer: AVAudioPCMBuffer) throws -> [Float] {
        let windowSize: Int
        if case .recording(let size) = mode {
            windowSize = size
        } else {
            windowSize = 100
        }
        
        return try extractAmplitudes(from: buffer, targetSamples: windowSize)
    }
    
    // MARK: - Private Methods
    
    private func createBuffer(from url: URL) throws -> AVAudioPCMBuffer {
        let ext = url.pathExtension.lowercased()
        
        // Check for OPUS files
        if ext == "opus" || ext == "ogg" {
            let opusDecoder = OpusDecoder()
            return try opusDecoder.decode(url: url)
        }
        
        // Standard formats
        let audioFile = try AVAudioFile(forReading: url)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw SamplingError.bufferCreationFailed
        }
        
        try audioFile.read(into: buffer)
        return buffer
    }
    
    /// Extract and downsample amplitudes from PCM buffer
    private func extractAmplitudes(from buffer: AVAudioPCMBuffer, targetSamples: Int) throws -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            throw SamplingError.invalidBuffer
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        // Use first channel (mono or left channel)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // If we have stereo, mix down to mono
        var monoSamples = samples
        if channelCount > 1 {
            monoSamples = mixToMono(samples: samples, 
                                   secondChannel: Array(UnsafeBufferPointer(start: channelData[1], count: frameLength)))
        }
        
        // Downsample to target sample count
        let downsampled = downsample(monoSamples, to: targetSamples)
        
        // Convert to RMS amplitudes
        let amplitudes = computeRMS(from: downsampled, bucketSize: max(1, downsampled.count / targetSamples))
        
        return amplitudes
    }
    
    /// Mix stereo to mono by averaging channels
    private func mixToMono(samples: [Float], secondChannel: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: samples.count)
        
        vDSP_vadd(samples, 1, secondChannel, 1, &output, 1, vDSP_Length(samples.count))
        
        var half: Float = 0.5
        vDSP_vsmul(output, 1, &half, &output, 1, vDSP_Length(output.count))
        
        return output
    }
    
    /// Downsample array to target size using averaging
    private func downsample(_ samples: [Float], to targetSize: Int) -> [Float] {
        guard samples.count > targetSize else {
            return samples
        }
        
        let bucketSize = samples.count / targetSize
        var downsampled = [Float](repeating: 0, count: targetSize)
        
        for i in 0..<targetSize {
            let startIndex = i * bucketSize
            let endIndex = min(startIndex + bucketSize, samples.count)
            let bucket = Array(samples[startIndex..<endIndex])
            
            // Average the bucket
            var sum: Float = 0
            vDSP_sve(bucket, 1, &sum, vDSP_Length(bucket.count))
            downsampled[i] = sum / Float(bucket.count)
        }
        
        return downsampled
    }
    
    /// Compute RMS (Root Mean Square) amplitudes
    private func computeRMS(from samples: [Float], bucketSize: Int) -> [Float] {
        let bucketCount = samples.count / bucketSize
        var rmsValues = [Float](repeating: 0, count: bucketCount)
        
        for i in 0..<bucketCount {
            let startIndex = i * bucketSize
            let endIndex = min(startIndex + bucketSize, samples.count)
            let bucket = Array(samples[startIndex..<endIndex])
            
            // Compute RMS: sqrt(mean(x^2))
            var squares = [Float](repeating: 0, count: bucket.count)
            vDSP_vsq(bucket, 1, &squares, 1, vDSP_Length(bucket.count))
            
            var mean: Float = 0
            vDSP_meanv(squares, 1, &mean, vDSP_Length(squares.count))
            
            rmsValues[i] = sqrt(mean)
        }
        
        return rmsValues
    }
}
