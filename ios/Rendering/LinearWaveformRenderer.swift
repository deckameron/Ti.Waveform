//
//  LinearWaveformRenderer.swift
//  TiWaveform
//
//  Renders linear striped waveform with vertical bars
//

import UIKit
import QuartzCore

public struct LinearWaveformConfiguration {
    var barWidth: CGFloat = 3.0
    var spacing: CGFloat = 2.0
    var cornerRadius: CGFloat = 1.5
    var activeColor: UIColor = .systemBlue
    var inactiveColor: UIColor = .systemGray4
    var minAmplitude: CGFloat = 0.4
    var maxAmplitude: CGFloat = 1.2
    var minBarHeight: CGFloat = 4.0
    var maxBarHeight: CGFloat? = nil
    var silenceThreshold: CGFloat = 0.05
    
    public init() {}
}

public protocol LinearWaveformRendererDelegate: AnyObject {
    func waveformDidSeek(to progress: CGFloat)
}

/// Renders linear waveform with vertical bars
public class LinearWaveformRenderer: UIView {
    
    public weak var delegate: LinearWaveformRendererDelegate?
    
    // MARK: - Properties
    
    public var configuration = LinearWaveformConfiguration() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Current playback progress (0.0 to 1.0)
    public var progress: CGFloat = 0.0 {
        didSet {
            progress = max(0.0, min(1.0, progress))
            updateProgressLayer()
        }
    }
    
    /// Waveform data model
    private var waveformModel: WaveformModel?
    
    /// Inactive waveform layer (background)
    private let inactiveLayer = CAShapeLayer()
    
    /// Active waveform layer (foreground, clipped by progress)
    private let activeLayer = CAShapeLayer()
    
    /// Mask layer for progress clipping
    private let maskLayer = CAShapeLayer()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        backgroundColor = .clear
        
        // Setup inactive layer
        inactiveLayer.fillColor = nil
        layer.addSublayer(inactiveLayer)
        
        // Setup active layer with mask
        activeLayer.fillColor = nil
        activeLayer.mask = maskLayer
        layer.addSublayer(activeLayer)
    }
    
    // MARK: - Public Methods
    
    /// Update waveform with model data
    /// - Parameter model: Waveform data model
    public func updateWaveform(model: WaveformModel) {
        self.waveformModel = model
        renderWaveform()
    }
    
    /// Set progress with optional animation
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - animated: Whether to animate the change
    private var displayLink: CADisplayLink?
    private var targetProgress: CGFloat = 0.0
    private var animationStartProgress: CGFloat = 0.0
    private var animationStartTime: CFTimeInterval = 0.0
    private let animationDuration: CFTimeInterval = 1.0

    public func setProgress(_ newProgress: CGFloat, animated: Bool) {
        // Cancelar animação anterior
        displayLink?.invalidate()
        displayLink = nil
        
        if animated {
            animationStartProgress = progress
            targetProgress = newProgress
            animationStartTime = CACurrentMediaTime()
            
            displayLink = CADisplayLink(target: self, selector: #selector(updateProgressAnimation))
            displayLink?.add(to: .main, forMode: .common)
        } else {
            progress = newProgress
        }
    }

    @objc private func updateProgressAnimation() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let t = min(elapsed / animationDuration, 1.0)
        
        // Ease in-out
        let easedT = t < 0.5
            ? 2 * t * t
            : 1 - pow(-2 * t + 2, 2) / 2
        
        progress = animationStartProgress + (targetProgress - animationStartProgress) * easedT
        
        if t >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
            progress = targetProgress
        }
    }
    
    // MARK: - Rendering
    
    private func renderWaveform() {
        
        guard let model = waveformModel, !model.isEmpty else {
            inactiveLayer.path = nil
            activeLayer.path = nil
            return
        }
        
        let barWidth = configuration.barWidth
        let spacing = configuration.spacing
        let totalBarWidth = barWidth + spacing
        
        // Calculate how many bars fit in the view
        let availableWidth = bounds.width
        let maxBars = Int(availableWidth / totalBarWidth)
        
        // Use actual sample count or max bars, whichever is smaller
        let barCount = min(maxBars, model.count)
        
        guard barCount > 0 else { return }
        
        var minAmp: Float = 1.0
        var maxAmp: Float = 0.0
        
        for i in 0..<barCount {
            let samplesPerBar = Float(model.count) / Float(barCount)
            let startSample = Int(Float(i) * samplesPerBar)
            let endSample = min(Int(Float(i + 1) * samplesPerBar), model.count)
            
            var peakAmp: Float = 0.0
            for sampleIdx in startSample..<endSample {
                let amp = model.amplitude(at: sampleIdx)
                peakAmp = max(peakAmp, amp)
            }
            
            minAmp = min(minAmp, peakAmp)
            maxAmp = max(maxAmp, peakAmp)
        }
        
        NSLog("🎵 Range: min=\(minAmp), max=\(maxAmp)")
        
        // Create paths for bars
        let inactivePath = UIBezierPath()
        let activePath = UIBezierPath()
        
        let centerY = bounds.height / 2
        let minHeight = configuration.minBarHeight
        let maxHeight = configuration.maxBarHeight ?? bounds.height
        
        for i in 0..<barCount {
            let x = CGFloat(i) * totalBarWidth
            
            // Get amplitude for this bar - downsample usando o MÁXIMO do range
            let samplesPerBar = Float(model.count) / Float(barCount)
            let startSample = Int(Float(i) * samplesPerBar)
            let endSample = min(Int(Float(i + 1) * samplesPerBar), model.count)

            // Pegar o PICO (valor máximo) desse range de samples
            var maxAmplitude: Float = 0.0
            for sampleIdx in startSample..<endSample {
                let amp = model.amplitude(at: sampleIdx)
                maxAmplitude = max(maxAmplitude, amp)
            }
            
            let normalized = maxAmp > minAmp
                ? (maxAmplitude - minAmp) / (maxAmp - minAmp)
                : 0.0
            
            var amplitude = CGFloat(normalized)
            
            if amplitude < configuration.silenceThreshold {
                amplitude = 0.0  // Tratar como silêncio total
            }
            
            // Calculate bar height
            let barHeight = amplitude > 0
                        ? minHeight + (maxHeight - minHeight) * amplitude
                        : minHeight
            
            // Create bar rect
            let barRect = CGRect(
                x: x,
                y: centerY - barHeight / 2,
                width: barWidth,
                height: barHeight
            )
            
            // Add rounded rectangle to both paths
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: configuration.cornerRadius)
            inactivePath.append(barPath)
            activePath.append(barPath)
        }
        
        // Update layers
        inactiveLayer.path = inactivePath.cgPath
        inactiveLayer.strokeColor = configuration.inactiveColor.cgColor
        inactiveLayer.fillColor = configuration.inactiveColor.cgColor
        inactiveLayer.lineWidth = 0
        
        activeLayer.path = activePath.cgPath
        activeLayer.strokeColor = configuration.activeColor.cgColor
        activeLayer.fillColor = configuration.activeColor.cgColor
        activeLayer.lineWidth = 0
        
        // Update mask for current progress
        updateProgressLayer()
    }
    
    private func updateProgressLayer() {
        let maskPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: bounds.width * progress,
            height: bounds.height
        ))
        
        maskLayer.path = maskPath.cgPath
    }
    
//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouch(touches)
//    }
//
//    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouch(touches)
//    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let newProgress = progressForTouch(at: location)
        
        progress = newProgress
        delegate?.waveformDidSeek(to: newProgress)
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        inactiveLayer.frame = bounds
        activeLayer.frame = bounds
        maskLayer.frame = bounds
        
        renderWaveform()
    }
    
    // MARK: - Color Animation
    
    /// Animate color change
    /// - Parameters:
    ///   - activeColor: New active color
    ///   - inactiveColor: New inactive color
    ///   - duration: Animation duration
    public func animateColors(activeColor: UIColor, inactiveColor: UIColor, duration: TimeInterval = 0.3) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        
        configuration.activeColor = activeColor
        configuration.inactiveColor = inactiveColor
        
        inactiveLayer.strokeColor = inactiveColor.cgColor
        inactiveLayer.fillColor = inactiveColor.cgColor
        
        activeLayer.strokeColor = activeColor.cgColor
        activeLayer.fillColor = activeColor.cgColor
        
        CATransaction.commit()
    }
}

// MARK: - Touch Handling for Scrubbing

extension LinearWaveformRenderer {
    
    /// Convert touch location to progress value
    /// - Parameter point: Touch point in view coordinates
    /// - Returns: Progress value (0.0 to 1.0)
    public func progressForTouch(at point: CGPoint) -> CGFloat {
        let progress = point.x / bounds.width
        return max(0.0, min(1.0, progress))
    }
}
