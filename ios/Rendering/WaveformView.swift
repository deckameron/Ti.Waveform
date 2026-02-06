//
//  WaveformMode.swift
//  TiWaveform
//
//  Created by Douglas Alves on 14/01/26.
//


//
//  WaveformView.swift
//  TiWaveform
//
//  Main waveform view with public API
//

import UIKit
import AVFoundation

public enum WaveformMode {
    case linear
    case circular
}

public enum WaveformState {
    case idle
    case loading
    case ready
    case playing
    case recording
    case paused
    case error(String)
}

public protocol WaveformViewDelegate: AnyObject {
    func waveformDidFinishLoading(_ waveform: WaveformView)
    func waveformDidUpdateProgress(_ waveform: WaveformView, progress: CGFloat)
    func waveformDidStartRecording(_ waveform: WaveformView)
    func waveformDidStopRecording(_ waveform: WaveformView)
    func waveformDidEncounterError(_ waveform: WaveformView, error: String)
    func waveformDidSeek(_ waveform: WaveformView, to progress: CGFloat)
    func waveformDidPauseRecording(_ waveform: WaveformView)
    func waveformDidResumeRecording(_ waveform: WaveformView)
}

/// Main waveform visualization view
public class WaveformView: UIView {
    
    // MARK: - Properties
    
    public weak var delegate: WaveformViewDelegate?
    
    public var mode: WaveformMode = .linear {
        didSet {
            switchMode()
        }
    }
    
    public private(set) var state: WaveformState = .idle {
        didSet {
            handleStateChange()
        }
    }
    
    /// Current progress (0.0 to 1.0)
    public private(set) var progress: CGFloat = 0.0
    
    /// Enable scrubbing
    public var isScrubbingEnabled: Bool = true {
        didSet {
            panGesture.isEnabled = isScrubbingEnabled && mode == .linear
        }
    }
    
    // Core components
    private let waveformModel = WaveformModel(mode: .global)
    private let amplitudeSampler: AmplitudeSampler
    
    // Renderers
    private var linearRenderer: LinearWaveformRenderer?
    private var circularRenderer: CircularWaveformRenderer?
    
    // Gesture recognizer for scrubbing
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        return gesture
    }()
    
    // Recording components
    private var audioRecorder: LiveWaveformRecorder?
    
    // Configuration
    public var linearConfiguration = LinearWaveformConfiguration() {
        didSet {
            linearRenderer?.configuration = linearConfiguration
        }
    }
    
    public var circularConfiguration = CircularWaveformConfiguration() {
        didSet {
            circularRenderer?.configuration = circularConfiguration
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        self.amplitudeSampler = AmplitudeSampler(mode: .playback(targetSamples: 200))
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        self.amplitudeSampler = AmplitudeSampler(mode: .playback(targetSamples: 200))
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        
        backgroundColor = .clear
        
        // Setup initial renderer
        switchMode()
        
        // Add gesture recognizer
        addGestureRecognizer(panGesture)
        panGesture.isEnabled = isScrubbingEnabled && mode == .linear
    }
    
    private func switchMode() {
        // Remove existing renderer
        linearRenderer?.removeFromSuperview()
        circularRenderer?.removeFromSuperview()
        
        switch mode {
        case .linear:
            let renderer = LinearWaveformRenderer(frame: bounds)
            renderer.configuration = linearConfiguration
            renderer.delegate = self 
            renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(renderer)
            linearRenderer = renderer
            
            // Update with current model if available
            if !waveformModel.isEmpty {
                renderer.updateWaveform(model: waveformModel)
                renderer.progress = progress
            }
            
            panGesture.isEnabled = isScrubbingEnabled
            
        case .circular:
            let renderer = CircularWaveformRenderer(frame: bounds)
            renderer.configuration = circularConfiguration
            renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(renderer)
            circularRenderer = renderer
            
            // Update with current model if available
            if !waveformModel.isEmpty {
                renderer.updateWaveform(model: waveformModel)
                renderer.progress = progress
            }
            
            panGesture.isEnabled = false // No scrubbing for circular
        }
    }
    
    // MARK: - Public API
    
    /// Load audio file for visualization
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - targetSamples: Number of samples to extract (default 200)
    public func loadAudio(from url: URL, targetSamples: Int = 200) {
        state = .loading
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Sample the audio file
                let amplitudes = try self.amplitudeSampler.sampleFile(at: url, targetSamples: targetSamples)
                
                DispatchQueue.main.async {
                    // Update model
                    self.waveformModel.update(amplitudes: amplitudes)
                    
                    // Update renderer
                    self.updateRenderer()
                    
                    self.state = .ready
                    self.delegate?.waveformDidFinishLoading(self)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(error.localizedDescription)
                    self.delegate?.waveformDidEncounterError(self, error: error.localizedDescription)
                }
            }
        }
    }
    
    /// Set playback progress
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - animated: Whether to animate
    public func setProgress(_ progress: CGFloat, animated: Bool = false) {
        self.progress = max(0.0, min(1.0, progress))
        
        switch mode {
        case .linear:
            linearRenderer?.setProgress(self.progress, animated: animated)
        case .circular:
            circularRenderer?.setProgress(self.progress, animated: animated)
        }
        
        delegate?.waveformDidUpdateProgress(self, progress: self.progress)
    }
    
    /// Start recording audio
    public func startRecording() {
        guard audioRecorder == nil else { return }
        
        // Create recorder
        let recorder = LiveWaveformRecorder()
        recorder.delegate = self
        
        do {
            try recorder.startRecording()
            audioRecorder = recorder
            state = .recording
            
            // Switch to dynamic normalization for recording
            waveformModel.clear()
            waveformModel.mode = .dynamic
            
            delegate?.waveformDidStartRecording(self)
        } catch {
            state = .error(error.localizedDescription)
            delegate?.waveformDidEncounterError(self, error: error.localizedDescription)
        }
    }
    
    /// Stop recording audio
    public func stopRecording() {
        audioRecorder?.stopRecording()
        audioRecorder = nil
        waveformModel.mode = .global
        state = .ready
        
        delegate?.waveformDidStopRecording(self)
    }
    
    /// Pause recording audio
    public func pauseRecording() {
        guard let recorder = audioRecorder else {
            NSLog("[WaveformView] ⚠️ No active recorder to pause")
            return
        }
        
        recorder.pauseRecording()
        state = .paused
        
        delegate?.waveformDidPauseRecording(self)
    }

    /// Resume recording audio
    public func resumeRecording() {
        guard let recorder = audioRecorder else {
            NSLog("[WaveformView] ⚠️ No active recorder to resume")
            return
        }
        
        recorder.resumeRecording()
        state = .recording
        
        delegate?.waveformDidResumeRecording(self)
    }
    
    /// Clear waveform data
    public func clear() {
        waveformModel.clear()
        progress = 0.0
        updateRenderer()
        state = .idle
    }
    
    /// Update colors with animation
    /// - Parameters:
    ///   - activeColor: Active (played) color
    ///   - inactiveColor: Inactive (unplayed) color
    ///   - animated: Whether to animate
    public func updateColors(activeColor: UIColor, inactiveColor: UIColor, animated: Bool = true) {
        if animated {
            switch mode {
            case .linear:
                linearRenderer?.animateColors(activeColor: activeColor, inactiveColor: inactiveColor)
            case .circular:
                circularRenderer?.animateColors(activeColor: activeColor, inactiveColor: inactiveColor)
            }
        } else {
            linearConfiguration.activeColor = activeColor
            linearConfiguration.inactiveColor = inactiveColor
            circularConfiguration.activeColor = activeColor
            circularConfiguration.inactiveColor = inactiveColor
            
            linearRenderer?.configuration = linearConfiguration
            circularRenderer?.configuration = circularConfiguration
        }
    }
    
    // MARK: - Private Methods
    
    private func updateRenderer() {
        switch mode {
        case .linear:
            linearRenderer?.updateWaveform(model: waveformModel)
        case .circular:
            circularRenderer?.updateWaveform(model: waveformModel)
        }
    }
    
    private func handleStateChange() {
        // Handle state-specific logic if needed
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isScrubbingEnabled, mode == .linear else { return }
        
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began, .changed:
            // Atualiza visualmente durante o scrub
            if let renderer = linearRenderer {
                let newProgress = renderer.progressForTouch(at: location)
                progress = newProgress
                renderer.progress = newProgress
            }
            
        case .ended:
            // Dispara o evento APENAS quando solta o dedo
            if let renderer = linearRenderer {
                let finalProgress = renderer.progressForTouch(at: location)
                progress = finalProgress
                renderer.progress = finalProgress
                delegate?.waveformDidSeek(self, to: finalProgress)
            }
            
        default:
            break
        }
    }
}

// MARK: - LiveWaveformRecorderDelegate

extension WaveformView: LiveWaveformRecorderDelegate {
    
    public func recorderDidUpdateAmplitude(_ recorder: LiveWaveformRecorder, amplitude: Float) {
        
        NSLog("📊 Received amplitude: \(amplitude), model count: \(waveformModel.count)")
        
        // Add amplitude to model
        waveformModel.append(amplitude: amplitude)
        
        // Update renderer
        updateRenderer()
        
        // Auto-scroll by updating progress
        if waveformModel.count > 0 {
            progress = 1.0
            setProgress(1.0, animated: false)
        }
    }
    
    public func recorderDidEncounterError(_ recorder: LiveWaveformRecorder, error: String) {
        state = .error(error)
        delegate?.waveformDidEncounterError(self, error: error)
    }
}


extension WaveformView: LinearWaveformRendererDelegate {
    public func waveformDidSeek(to progress: CGFloat) {
        self.progress = progress
        delegate?.waveformDidSeek(self, to: progress)
    }
}
