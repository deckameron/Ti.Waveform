//
//  LiveWaveformRecorder.swift
//  TiWaveform
//
//  Handles live audio recording with amplitude feedback
//

import AVFoundation
import Accelerate

public protocol LiveWaveformRecorderDelegate: AnyObject {
    func recorderDidUpdateAmplitude(_ recorder: LiveWaveformRecorder, amplitude: Float)
    func recorderDidEncounterError(_ recorder: LiveWaveformRecorder, error: String)
}

public class LiveWaveformRecorder {
    
    // MARK: - Properties
    
    public weak var delegate: LiveWaveformRecorderDelegate?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    private let updateInterval: TimeInterval = 0.05 // 50ms updates
    private var updateTimer: Timer?
    private var isRecording = false
    private var isPaused = false
    
    private var currentAmplitude: Float = 0.0
    private let amplitudeSmoothing: Float = 0.3 // Smoothing factor
    
    // MARK: - Public Methods
    
    /// Start recording audio
    public func startRecording() throws {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                self?.delegate?.recorderDidEncounterError(self!, error: "Microphone permission denied")
                return
            }
            
            DispatchQueue.main.async {
                self?.setupAudioEngine()
            }
        }
    }
    
    /// Stop recording audio
    public func stopRecording() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
    }
    
    /// Pause recording
    public func pauseRecording() {
        guard isRecording, !isPaused else {
            NSLog("[RecordingWaveformRenderer] ⚠️ Not recording or already paused")
            return
        }
        
        // Pausar o audio engine
        audioEngine?.pause()
        isPaused = true
        
        NSLog("[RecordingWaveformRenderer] ⏸️ Recording paused")
    }

    /// Resume recording
    public func resumeRecording() {
        guard isRecording, isPaused else {
            NSLog("[RecordingWaveformRenderer] ⚠️ Not paused or not recording")
            return
        }
        
        // Resumir o audio engine
        do {
            try audioEngine?.start()
            isPaused = false
            NSLog("[RecordingWaveformRenderer] ▶️ Recording resumed")
        } catch {
            NSLog("[RecordingWaveformRenderer] ❌ Failed to resume: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
            
            // Create audio engine
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            inputNode = audioEngine.inputNode
            guard let inputNode = inputNode else { return }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Install tap to capture audio
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
                self?.processBuffer(buffer)
            }
            
            // Start the engine
            try audioEngine.start()
            
            // Start update timer
            startUpdateTimer()
            
        } catch {
            delegate?.recorderDidEncounterError(self, error: error.localizedDescription)
        }
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
 
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        // Get samples from first channel
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Calculate RMS amplitude
        var rms: Float = 0.0
        var squares = [Float](repeating: 0, count: samples.count)
        
        // Square each sample
        vDSP_vsq(samples, 1, &squares, 1, vDSP_Length(samples.count))
        
        // Calculate mean
        var mean: Float = 0.0
        vDSP_meanv(squares, 1, &mean, vDSP_Length(squares.count))
        
        // Take square root
        rms = sqrt(mean)
        
        // Apply smoothing
        currentAmplitude = currentAmplitude * (1 - amplitudeSmoothing) + rms * amplitudeSmoothing
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            NSLog("🎤 Recording amplitude: \(self.currentAmplitude)")
            
            self.delegate?.recorderDidUpdateAmplitude(self, amplitude: self.currentAmplitude)
        }
    }
}
