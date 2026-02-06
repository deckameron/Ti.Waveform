//
//  NormalizationMode.swift
//  TiWaveform
//
//  Created by Douglas Alves on 14/01/26.
//


//
//  WaveformModel.swift
//  TiWaveform
//
//  Data model for waveform amplitudes with normalization
//

import Foundation

public enum NormalizationMode {
    case global      // Normalize across entire dataset (playback)
    case dynamic     // Normalize within sliding window (recording)
}

/// Model that stores normalized amplitude data ready for rendering
public class WaveformModel {
    
    // MARK: - Properties
    
    /// Raw amplitude values (0.0 to 1.0, pre-normalization)
    private(set) var rawAmplitudes: [Float] = []
    
    /// Normalized amplitudes ready for rendering (0.0 to 1.0)
    private(set) var normalizedAmplitudes: [Float] = []
    
    /// Minimum amplitude multiplier (default 0.4 = 40%)
    public var minAmplitude: Float = 0.4
    
    /// Maximum amplitude multiplier (default 1.2 = 120%)
    public var maxAmplitude: Float = 1.2
    
    /// Normalization mode
    public var mode: NormalizationMode
    
    /// Maximum value in the dataset (for global normalization)
    private var globalMax: Float = 0.0
    
    // MARK: - Initialization
    
    public init(mode: NormalizationMode = .global) {
        self.mode = mode
    }
    
    // MARK: - Public Methods
    
    /// Update the model with new amplitude data
    /// - Parameter amplitudes: Raw amplitude values
    public func update(amplitudes: [Float]) {
        self.rawAmplitudes = amplitudes
        
        switch mode {
        case .global:
            normalizeGlobal()
        case .dynamic:
            normalizeDynamic()
        }
    }
    
    /// Append new amplitude (for live recording)
    /// - Parameter amplitude: Single amplitude value
    public func append(amplitude: Float) {
        rawAmplitudes.append(amplitude)
        
        // Re-normalize if in dynamic mode
        if case .dynamic = mode {
            normalizeDynamic()
        }
    }
    
    /// Clear all amplitude data
    public func clear() {
        rawAmplitudes.removeAll()
        normalizedAmplitudes.removeAll()
        globalMax = 0.0
    }
    
    /// Get amplitude at specific index with scaling applied
    /// - Parameter index: Index in the amplitude array
    /// - Returns: Scaled amplitude value
    public func amplitude(at index: Int) -> Float {
        guard index >= 0 && index < normalizedAmplitudes.count else {
            return 0.0
        }
        return normalizedAmplitudes[index]
    }
    
    /// Get amplitudes in a specific range
    /// - Parameters:
    ///   - startIndex: Start index (inclusive)
    ///   - endIndex: End index (exclusive)
    /// - Returns: Array of amplitudes in range
    public func amplitudes(in range: Range<Int>) -> [Float] {
        let safeStart = max(0, range.lowerBound)
        let safeEnd = min(normalizedAmplitudes.count, range.upperBound)
        
        guard safeStart < safeEnd else {
            return []
        }
        
        return Array(normalizedAmplitudes[safeStart..<safeEnd])
    }
    
    // MARK: - Private Methods
    
    /// Global normalization - normalize across entire dataset
    private func normalizeGlobal() {
        guard !rawAmplitudes.isEmpty else {
            normalizedAmplitudes = []
            return
        }
        
        // Find global maximum
        globalMax = rawAmplitudes.max() ?? 1.0
        
        // Prevent division by zero
        if globalMax < 0.0001 {
            globalMax = 1.0
        }
        
        // Normalize to 0-1 range
        var normalized = rawAmplitudes.map { $0 / globalMax }
        
        // Apply min/max amplitude scaling
        normalized = normalized.map { value in
            let scaled = value * (maxAmplitude - minAmplitude) + minAmplitude
            return min(max(scaled, 0.0), maxAmplitude)
        }
        
        normalizedAmplitudes = normalized
    }
    
    /// Dynamic normalization - normalize within sliding window (for recording)
    private func normalizeDynamic() {
        guard !rawAmplitudes.isEmpty else {
            normalizedAmplitudes = []
            return
        }
        
        // Update global max if we have a new peak (only grows, never shrinks)
        let currentMax = rawAmplitudes.max() ?? 0.0
        if currentMax > globalMax {
            globalMax = currentMax
        }
        
        // Prevent division by zero - use minimum threshold
        let safeMax = max(globalMax, 0.01) // Threshold de 0.01 para evitar silêncio absoluto
        
        // Normalize all values using the growing peak
        var normalized = rawAmplitudes.map { $0 / safeMax }
        
        // Apply min/max amplitude scaling
        normalized = normalized.map { value in
            let scaled = value * (maxAmplitude - minAmplitude) + minAmplitude
            return min(max(scaled, 0.0), maxAmplitude)
        }
        
        normalizedAmplitudes = normalized
    }
    
    // MARK: - Computed Properties
    
    /// Number of samples in the model
    public var count: Int {
        return normalizedAmplitudes.count
    }
    
    /// Check if model has data
    public var isEmpty: Bool {
        return normalizedAmplitudes.isEmpty
    }
    
    /// Get average amplitude
    public var averageAmplitude: Float {
        guard !normalizedAmplitudes.isEmpty else {
            return 0.0
        }
        return normalizedAmplitudes.reduce(0, +) / Float(normalizedAmplitudes.count)
    }
    
    /// Get peak amplitude
    public var peakAmplitude: Float {
        return normalizedAmplitudes.max() ?? 0.0
    }
}
