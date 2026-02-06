//
//  TiWaveformViewProxy.swift
//  TiWaveform
//
//  Titanium view proxy for WaveformView
//

import UIKit
import TitaniumKit
import AVFoundation


@objc(TiWaveformViewProxy)
class TiWaveformViewProxy: TiViewProxy {
    
    // MARK: - Properties
    
    private var waveformView: TiWaveformView? {
        return view as? TiWaveformView
    }
    
    // MARK: - View Creation
    
    override func newView() -> TiUIView! {
        return TiWaveformView(frame: .zero)
    }
    
    // MARK: - Public Properties
    
    /// Waveform mode (MODE_LINEAR or MODE_CIRCULAR)
    @objc public var mode: NSNumber? {
        get {
            return waveformView?.mode
        }
        set {
            waveformView?.mode = newValue
        }
    }
    
    /// Current progress (0.0 to 1.0)
    @objc public var progress: NSNumber? {
        get {
            return waveformView?.currentProgress
        }
        set {
            guard let value = newValue else { return }
            waveformView?.setProgress(value, animated: false)
        }
    }
    
    /// Enable scrubbing
    @objc public var scrubbingEnabled: NSNumber? {
        get {
            return waveformView?.scrubbingEnabled
        }
        set {
            waveformView?.scrubbingEnabled = newValue
        }
    }
    
    // MARK: - Shared Configuration (Linear & Circular)
    
    @objc public var barWidth: NSNumber? {
        didSet {
            waveformView?.barWidth = barWidth
        }
    }
    
    @objc public var barSpacing: NSNumber? {
        didSet {
            waveformView?.barSpacing = barSpacing
        }
    }
    
    @objc public var cornerRadius: NSNumber? {
        didSet {
            waveformView?.cornerRadius = cornerRadius
        }
    }
    
    // Colors
    @objc public var activeColor: String? {
        didSet {
            waveformView?.activeColor = activeColor
        }
    }
    
    @objc public var inactiveColor: String? {
        didSet {
            waveformView?.inactiveColor = inactiveColor
        }
    }
    
    // Amplitude scaling
    @objc public var minAmplitude: NSNumber? {
        didSet {
            waveformView?.minAmplitude = minAmplitude
        }
    }
    
    @objc public var maxAmplitude: NSNumber? {
        didSet {
            waveformView?.maxAmplitude = maxAmplitude
        }
    }
    
    @objc public var silenceThreshold: NSNumber? {
        didSet {
            waveformView?.silenceThreshold = silenceThreshold
        }
    }
    
    // MARK: - Linear-Specific Configuration
    
    @objc public var minBarHeight: NSNumber? {
        didSet {
            waveformView?.minBarHeight = minBarHeight
        }
    }
    
    @objc public var maxBarHeight: NSNumber? {
        didSet {
            waveformView?.maxBarHeight = maxBarHeight
        }
    }
    
    // MARK: - Circular-Specific Configuration
    
    @objc public var innerRadiusRatio: NSNumber? {
        didSet {
            waveformView?.innerRadiusRatio = innerRadiusRatio
        }
    }
    
    @objc public var minRadiusAmplitude: NSNumber? {
        didSet {
            waveformView?.minRadiusAmplitude = minRadiusAmplitude
        }
    }
    
    @objc public var maxRadiusAmplitude: NSNumber? {
        didSet {
            waveformView?.maxRadiusAmplitude = maxRadiusAmplitude
        }
    }
    
    @objc public var circularAnimationType: NSNumber? {
        didSet {
            waveformView?.circularAnimationType = circularAnimationType
        }
    }
    
    // MARK: - Public Methods
    
    /// Load audio file
    @objc(loadAudio:)
    func loadAudio(_ args: [Any]?) {
        guard let args = args, !args.isEmpty else {
            fireEvent("error", with: ["message": "Missing parameters"])
            return
        }
        
        guard let params = args[0] as? [String: Any] else {
            fireEvent("error", with: ["message": "Invalid parameters format. Expected dictionary with 'audioSource' and 'maxBarCount'"])
            return
        }
        
        // Obter audioSource (obrigatório)
        guard let audioSource = params["audioSource"] as? String else {
            fireEvent("error", with: ["message": "Missing required parameter 'audioSource'"])
            return
        }
        
        // Obter maxBarCount (opcional, padrão = 200)
        let maxBarCount = params["maxBarCount"] as? Int ?? 200
        
        waveformView?.loadAudio(path: audioSource, targetSamples: maxBarCount)
    }
    
    /// Set progress with optional animation
    @objc(seekToProgress:)
    func setProgress(_ args: [Any]?) {
        guard let args = args, !args.isEmpty else { return }
        
        var progress: CGFloat = 0.0
        var animated = false
        
        if let value = args[0] as? NSNumber {
            progress = CGFloat(value.floatValue)
        }
        
        if args.count > 1, let anim = args[1] as? Bool {
            animated = anim
        }
        
        waveformView?.setProgressValue(progress, animated: animated)
    }
    
    /// Start recording
    @objc(startRecording:)
    func startRecording(_ args: [Any]?) {
        guard let waveformView = waveformView else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
                NSLog("[TiWaveform] ✅ AVAudioSession configured for recording")
            } catch {
                NSLog("[TiWaveform] ⚠️ Failed to configure AVAudioSession: \(error)")
            }
            
            // Voltar ao main thread para iniciar a gravação
            DispatchQueue.main.async {
                waveformView.startRecording()
            }
        }
    }
    
    /// Stop recording
    @objc(stopRecording:)
    func stopRecording(_ args: [Any]?) {
        guard let waveformView = waveformView else { return }
        
        waveformView.stopRecording()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                // Primeiro desativar
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                // Depois mudar categoria
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                NSLog("[TiWaveform] ✅ AVAudioSession restored to playback")
            } catch {
                NSLog("[TiWaveform] ⚠️ Failed to restore AVAudioSession: \(error)")
            }
        }
    }
    
    @objc(pauseRecording:)
    public func pauseRecording(_ args: [Any]?) {
        guard let waveformView = waveformView else { return }
        waveformView.pauseRecording()
    }

    @objc(resumeRecording:)
    public func resumeRecording(_ args: [Any]?) {
        guard let waveformView = waveformView else { return }
        waveformView.resumeRecording()
    }
    
    /// Clear waveform
    @objc(clear:)
    func clear(_ args: [Any]?) {
        waveformView?.clear()
    }
    
    /// Update colors with animation
    @objc(updateColors:)
    func updateColors(_ args: [Any]?) {
        guard let args = args, !args.isEmpty else { return }
        guard let colorDict = args[0] as? [String: Any] else { return }
        
        let activeColor = colorDict["active"] as? String
        let inactiveColor = colorDict["inactive"] as? String
        let animated = colorDict["animated"] as? Bool ?? true
        
        waveformView?.updateColors(activeColor: activeColor,
                                   inactiveColor: inactiveColor,
                                   animated: animated)
    }
    
    // MARK: - Event Firing Helpers
    
    func fireLoadingComplete() {
        fireEvent("loadingComplete", with: nil)
    }
    
    func fireProgressUpdate(progress: Float) {
        fireEvent("progress", with: ["value": progress])
    }
    
    func fireRecordingStarted() {
        fireEvent("recordingStarted", with: nil)
    }
    
    func fireRecordingStopped() {
        fireEvent("recordingStopped", with: nil)
    }
    
    func fireError(message: String) {
        fireEvent("error", with: ["message": message])
    }
    
    @objc func fireSeek(progress: Float) {
        fireEvent("seek", with: ["progress": progress])
    }
    
    func fireRecordingPaused() {
        fireEvent("recordingPaused", with: nil)
    }

    func fireRecordingResumed() {
        fireEvent("recordingResumed", with: nil)
    }
}
