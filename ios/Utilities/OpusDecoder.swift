//
//  OpusDecoder.swift
//  TiWaveform
//
//  OPUS decoder usando AVFoundation nativo
//

import AVFoundation

/// OPUS audio decoder usando AVFoundation
public class OpusDecoder {
    
    // MARK: - Public Methods
    
    /// Decode OPUS file to PCM buffer
    /// - Parameter url: OPUS file URL (.opus or .ogg)
    /// - Returns: PCM buffer with decoded audio
    public func decode(url: URL) throws -> AVAudioPCMBuffer {
        
        // iOS 13+ tem suporte nativo para OPUS via AVAudioFile!
        // Mas precisa converter .opus para formato reconhecido
        
        if url.pathExtension.lowercased() == "opus" || url.pathExtension.lowercased() == "ogg" {
            // Tentar carregar diretamente
            do {
                return try decodeWithAVAudioFile(url: url)
            } catch {
                // Se falhar, tentar conversão
                return try decodeWithConversion(url: url)
            }
        }
        
        return try decodeWithAVAudioFile(url: url)
    }
    
    // MARK: - Private Methods
    
    /// Decode usando AVAudioFile direto
    private func decodeWithAVAudioFile(url: URL) throws -> AVAudioPCMBuffer {
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
    
    /// Decode com conversão via AVAssetReader
    private func decodeWithConversion(url: URL) throws -> AVAudioPCMBuffer {
        let asset = AVURLAsset(url: url)
        
        guard let assetTrack = asset.tracks(withMediaType: .audio).first else {
            throw SamplingError.unsupportedFormat
        }
        
        let reader = try AVAssetReader(asset: asset)
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let output = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettings)
        reader.add(output)
        
        guard reader.startReading() else {
            throw SamplingError.decodingFailed
        }
        
        var samples: [Float] = []
        
        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                continue
            }
            
            var length = 0
            var data: UnsafeMutablePointer<Int8>?
            
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &data)
            
            if let data = data {
                let floatData = data.withMemoryRebound(to: Float.self, capacity: length / MemoryLayout<Float>.size) { $0 }
                let count = length / MemoryLayout<Float>.size
                samples.append(contentsOf: UnsafeBufferPointer(start: floatData, count: count))
            }
        }
        
        reader.cancelReading()
        
        // Criar buffer com os samples
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            throw SamplingError.bufferCreationFailed
        }
        
        buffer.frameLength = AVAudioFrameCount(samples.count)
        buffer.floatChannelData![0].update(from: samples, count: samples.count)
        
        return buffer
    }
}
