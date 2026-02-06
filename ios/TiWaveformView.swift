//
//  TiWaveformView.swift
//  TiWaveform
//
//  Titanium UIView wrapper for WaveformView
//

import UIKit
import TitaniumKit

class TiWaveformView: TiUIView {
    
    // MARK: - Properties
    
    private var waveformView: WaveformView!
    
    private var viewProxy: TiWaveformViewProxy? {
        return proxy as? TiWaveformViewProxy
    }
    
    // Configuration storage
    var mode: NSNumber? {
        didSet {
            updateMode()
        }
    }
    
    var currentProgress: NSNumber? {
        return NSNumber(value: Float(waveformView.progress))
    }
    
    var scrubbingEnabled: NSNumber? {
        didSet {
            waveformView.isScrubbingEnabled = scrubbingEnabled?.boolValue ?? true
        }
    }
    
    // Linear configuration
    var barWidth: NSNumber? {
        didSet {
            let value = CGFloat(barWidth?.floatValue ?? 3.0)
            waveformView.linearConfiguration.barWidth = value
            waveformView.circularConfiguration.barWidth = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }

    var barSpacing: NSNumber? {
        didSet {
            let value = CGFloat(barSpacing?.floatValue ?? 2.0)
            waveformView.linearConfiguration.spacing = value
            waveformView.circularConfiguration.barSpacing = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }

    var cornerRadius: NSNumber? {
        didSet {
            let value = CGFloat(cornerRadius?.floatValue ?? 1.5)
            waveformView.linearConfiguration.cornerRadius = value
            waveformView.circularConfiguration.cornerRadius = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }
    
    // Colors
    var activeColor: String? {
        didSet {
            updateColors()
        }
    }
    
    var inactiveColor: String? {
        didSet {
            updateColors()
        }
    }
    
    // Amplitude scaling
    var minAmplitude: NSNumber? {
        didSet {
            let value = CGFloat(minAmplitude?.floatValue ?? 0.4)
            waveformView.linearConfiguration.minAmplitude = value
            waveformView.circularConfiguration.minAmplitude = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }
    
    var maxAmplitude: NSNumber? {
        didSet {
            let value = CGFloat(maxAmplitude?.floatValue ?? 1.2)
            waveformView.linearConfiguration.maxAmplitude = value
            waveformView.circularConfiguration.maxAmplitude = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }
    
    // Circular configuration
    var innerRadiusRatio: NSNumber? {
        didSet {
            waveformView.circularConfiguration.innerRadiusRatio = CGFloat(innerRadiusRatio?.floatValue ?? 0.3)
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }

    var minRadiusAmplitude: NSNumber? {
        didSet {
            waveformView.circularConfiguration.minRadiusAmplitude = CGFloat(minRadiusAmplitude?.floatValue ?? 0.1)
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }

    var maxRadiusAmplitude: NSNumber? {
        didSet {
            waveformView.circularConfiguration.maxRadiusAmplitude = CGFloat(maxRadiusAmplitude?.floatValue ?? 1.0)
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }

    var silenceThreshold: NSNumber? {
        didSet {
            let value = CGFloat(silenceThreshold?.floatValue ?? 0.05)
            waveformView.linearConfiguration.silenceThreshold = value
            waveformView.circularConfiguration.silenceThreshold = value
            waveformView.linearConfiguration = waveformView.linearConfiguration
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        // Create waveform view
        waveformView = WaveformView(frame: bounds)
        waveformView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        waveformView.delegate = self
        addSubview(waveformView)
    }
    
    // MARK: - Layout
    
    override func frameSizeChanged(_ frame: CGRect, bounds: CGRect) {
        super.frameSizeChanged(frame, bounds: bounds)
        TiUtils.setView(waveformView, positionRect: bounds)
    }
    
    // MARK: - Public Methods
    
    func loadAudio(path: String, targetSamples: Int) {
        // Convert Titanium path to URL
        let url = URL(fileURLWithPath: path)
        waveformView.loadAudio(from: url, targetSamples: targetSamples)
    }
    
    func setProgress(_ progress: NSNumber, animated: Bool) {
        let value = CGFloat(progress.floatValue)
        waveformView.setProgress(value, animated: animated)
    }
    
    func startRecording() {
        waveformView.startRecording()
    }
    
    func stopRecording() {
        waveformView.stopRecording()
    }
    
    func pauseRecording() {
        waveformView.pauseRecording()
    }

    func resumeRecording() {
        waveformView.resumeRecording()
    }
    
    func clear() {
        waveformView.clear()
    }
    
    var circularAnimationType: NSNumber? {
        didSet {
            waveformView.circularConfiguration.animationType = circularAnimationType?.intValue ?? 0
            waveformView.circularConfiguration = waveformView.circularConfiguration
        }
    }
    
    func updateColors(activeColor: String?, inactiveColor: String?, animated: Bool) {
        let active = activeColor != nil ? TiUtils.colorValue(activeColor)?.color : waveformView.linearConfiguration.activeColor
        let inactive = inactiveColor != nil ? TiUtils.colorValue(inactiveColor)?.color : waveformView.linearConfiguration.inactiveColor
        
        if let active = active, let inactive = inactive {
            waveformView.updateColors(activeColor: active, inactiveColor: inactive, animated: animated)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateMode() {
        guard let modeValue = mode?.intValue else { return }
        
        switch modeValue {
        case 0: // MODE_LINEAR
            waveformView.mode = .linear
        case 1: // MODE_CIRCULAR
            waveformView.mode = .circular
        default:
            waveformView.mode = .linear
        }
    }
    
    private func updateColors() {
        var active: UIColor?
        var inactive: UIColor?
        
        if let activeColorStr = activeColor {
            active = TiUtils.colorValue(activeColorStr)?.color
        }
        
        if let inactiveColorStr = inactiveColor {
            inactive = TiUtils.colorValue(inactiveColorStr)?.color
        }
        
        if let active = active {
            waveformView.linearConfiguration.activeColor = active
            waveformView.circularConfiguration.activeColor = active
        }
        
        if let inactive = inactive {
            waveformView.linearConfiguration.inactiveColor = inactive
            waveformView.circularConfiguration.inactiveColor = inactive
        }
        
        waveformView.linearConfiguration = waveformView.linearConfiguration
        waveformView.circularConfiguration = waveformView.circularConfiguration
    }
    
    var minBarHeight: NSNumber? {
        didSet {
            waveformView.linearConfiguration.minBarHeight = CGFloat(minBarHeight?.floatValue ?? 4.0)
            waveformView.linearConfiguration = waveformView.linearConfiguration
        }
    }

    var maxBarHeight: NSNumber? {
        didSet {
            if let value = maxBarHeight?.floatValue {
                waveformView.linearConfiguration.maxBarHeight = CGFloat(value)
            } else {
                waveformView.linearConfiguration.maxBarHeight = nil
            }
            waveformView.linearConfiguration = waveformView.linearConfiguration
        }
    }
}

// MARK: - WaveformViewDelegate

extension TiWaveformView: WaveformViewDelegate {
    
    func waveformDidFinishLoading(_ waveform: WaveformView) {
        viewProxy?.fireLoadingComplete()
    }
    
    func waveformDidUpdateProgress(_ waveform: WaveformView, progress: CGFloat) {
        viewProxy?.fireProgressUpdate(progress: Float(progress))
    }
    
    func waveformDidStartRecording(_ waveform: WaveformView) {
        viewProxy?.fireRecordingStarted()
    }
    
    func waveformDidStopRecording(_ waveform: WaveformView) {
        viewProxy?.fireRecordingStopped()
    }
    
    // ← ADICIONE ESTES DOIS MÉTODOS:
    func waveformDidPauseRecording(_ waveform: WaveformView) {
        viewProxy?.fireRecordingPaused()
    }
    
    func waveformDidResumeRecording(_ waveform: WaveformView) {
        viewProxy?.fireRecordingResumed()
    }
    
    func waveformDidEncounterError(_ waveform: WaveformView, error: String) {
        viewProxy?.fireError(message: error)
    }
    
    func waveformDidSeek(_ waveform: WaveformView, to progress: CGFloat) {
        viewProxy?.fireSeek(progress: Float(progress))
    }
}
