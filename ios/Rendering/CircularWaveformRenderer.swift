//
//  CircularWaveformRenderer.swift
//  TiWaveform
//
//  Renders circular radial waveform with rectangular bars
//

import UIKit
import QuartzCore

public struct CircularWaveformConfiguration {
    var barWidth: CGFloat = 4.0            // Largura angular da barra (em graus)
    var barSpacing: CGFloat = 2.0          // Espaçamento angular entre barras (em graus)
    var cornerRadius: CGFloat = 2.0        // Raio dos cantos arredondados
    var activeColor: UIColor = .systemBlue
    var inactiveColor: UIColor = .systemGray4
    var minAmplitude: CGFloat = 0.4
    var maxAmplitude: CGFloat = 1.2
    var innerRadiusRatio: CGFloat = 0.3    // Raio interno como proporção do raio externo
    var minRadiusAmplitude: CGFloat = 0.1  // Amplitude mínima do raio
    var maxRadiusAmplitude: CGFloat = 1.0  // Amplitude máxima do raio
    var silenceThreshold: CGFloat = 0.05   // Threshold de silêncio
    var animationType: Int = 1             // 0 = RADIAL, 1 = FLOW
    
    public init() {}
}

/// Renders circular waveform with radial rectangular bars
public class CircularWaveformRenderer: UIView {
    
    // MARK: - Properties
    
    public var configuration = CircularWaveformConfiguration() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Current playback progress (0.0 to 1.0)
    private var _progress: CGFloat = 0.0

    public var progress: CGFloat {
        get { return _progress }
        set {
            _progress = max(0.0, min(1.0, newValue))
            setNeedsDisplay()
        }
    }
    
    /// Waveform data model
    private var waveformModel: WaveformModel?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    // MARK: - Public Methods
    
    /// Update waveform with model data
    /// - Parameter model: Waveform data model
    public func updateWaveform(model: WaveformModel) {
        self.waveformModel = model
        setNeedsDisplay()
    }
    
    /// MARK: - Animation Properties
    
    private var displayLink: CADisplayLink?
    private var targetProgress: CGFloat = 0.0
    private var animationStartProgress: CGFloat = 0.0
    private var animationStartTime: CFTimeInterval = 0.0
    private let animationDuration: CFTimeInterval = 1.0

    // MARK: - Public Methods (substitua o setProgress existente)

    /// Set progress with optional animation
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - animated: Whether to animate the change
    public func setProgress(_ newProgress: CGFloat, animated: Bool) {
        // Cancelar animação anterior
        displayLink?.invalidate()
        displayLink = nil
        
        NSLog("🎯 setProgress called: newProgress=\(newProgress), animated=\(animated), current=\(_progress)")
        
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
        
        _progress = animationStartProgress + (targetProgress - animationStartProgress) * easedT
                
        setNeedsDisplay()
        
        if t >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
            _progress = targetProgress
            NSLog("🔄 Animation FINISHED at progress=\(_progress)")
            setNeedsDisplay()
        }
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        guard let model = waveformModel, !model.isEmpty else {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let outerRadius = maxRadius * 0.95
        let innerRadius = outerRadius * configuration.innerRadiusRatio
        let availableRadius = outerRadius - innerRadius
        
        // Calcular quantas barras cabem
        let barWidthDegrees = configuration.barWidth
        let barSpacingDegrees = configuration.barSpacing
        let totalBarAngle = barWidthDegrees + barSpacingDegrees
        let maxBars = Int(360.0 / totalBarAngle)
        let barCount = min(maxBars, model.count)
        
        guard barCount > 0 else { return }
        
        // Re-normalização
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
        
        let angleStepRadians = totalBarAngle * CGFloat.pi / 180.0
        let barWidthRadians = barWidthDegrees * CGFloat.pi / 180.0
        let progressAngle = 2 * CGFloat.pi * progress
        
        for i in 0..<barCount {
            // Calcular amplitude
            let samplesPerBar = Float(model.count) / Float(barCount)
            let startSample = Int(Float(i) * samplesPerBar)
            let endSample = min(Int(Float(i + 1) * samplesPerBar), model.count)
            
            var peakAmplitude: Float = 0.0
            for sampleIdx in startSample..<endSample {
                let amp = model.amplitude(at: sampleIdx)
                peakAmplitude = max(peakAmplitude, amp)
            }
            
            let normalized = maxAmp > minAmp
                ? (peakAmplitude - minAmp) / (maxAmp - minAmp)
                : 0.0
            
            var amplitude = CGFloat(normalized)
            
            if amplitude < configuration.silenceThreshold {
                amplitude = 0.0
            }
            
            let barLength = amplitude > 0
                ? availableRadius * (configuration.minRadiusAmplitude + amplitude * (configuration.maxRadiusAmplitude - configuration.minRadiusAmplitude))
                : availableRadius * configuration.minRadiusAmplitude
            
            let angle = CGFloat(i) * angleStepRadians - CGFloat.pi / 2
            
            // Calcular quanto desta barra está ativa
            let barStartAngle = angle + CGFloat.pi / 2
            let barEndAngle = barStartAngle + barWidthRadians
            
            var activePercentage: CGFloat = 0.0
            
            if progressAngle >= barEndAngle {
                activePercentage = 1.0
            } else if progressAngle > barStartAngle {
                activePercentage = (progressAngle - barStartAngle) / barWidthRadians
            }
            
            // Escolher tipo de animação
            if configuration.animationType == 0 {
                // RADIAL: preenche de dentro para fora
                drawRadialAnimation(
                    context: context,
                    center: center,
                    angle: angle,
                    innerRadius: innerRadius,
                    barLength: barLength,
                    activePercentage: activePercentage
                )
            } else {
                // FLOW: preenche no sentido angular
                drawFlowAnimation(
                    context: context,
                    center: center,
                    angle: angle,
                    innerRadius: innerRadius,
                    barLength: barLength,
                    barWidthRadians: barWidthRadians,
                    activePercentage: activePercentage
                )
            }
        }
    }

    // MARK: - Animation Methods

    private func drawRadialAnimation(
        context: CGContext,
        center: CGPoint,
        angle: CGFloat,
        innerRadius: CGFloat,
        barLength: CGFloat,
        activePercentage: CGFloat
    ) {
        if activePercentage > 0.0 {
            let activeLength = barLength * activePercentage
            drawRotatedBar(
                context: context,
                center: center,
                angle: angle,
                innerRadius: innerRadius,
                barLength: activeLength,
                barWidth: configuration.barWidth,  // ← PIXELS
                color: configuration.activeColor,
                cornerRadius: configuration.cornerRadius
            )
        }
        
        if activePercentage < 1.0 {
            let inactiveStartRadius = innerRadius + (barLength * activePercentage)
            let inactiveLength = barLength * (1.0 - activePercentage)
            
            drawRotatedBar(
                context: context,
                center: center,
                angle: angle,
                innerRadius: inactiveStartRadius,
                barLength: inactiveLength,
                barWidth: configuration.barWidth,  // ← PIXELS
                color: configuration.inactiveColor,
                cornerRadius: configuration.cornerRadius
            )
        }
    }

    private func drawFlowAnimation(
        context: CGContext,
        center: CGPoint,
        angle: CGFloat,
        innerRadius: CGFloat,
        barLength: CGFloat,
        barWidthRadians: CGFloat,
        activePercentage: CGFloat
    ) {
        let barWidthDegrees = configuration.barWidth
        
        if activePercentage > 0.0 {
            // Parte ATIVA - começa da DIREITA (trailing edge)
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: angle)
            
            let activeWidth = barWidthDegrees * activePercentage
            
            let barRect = CGRect(
                x: barWidthDegrees / 2 - activeWidth,  // ← INVERTIDO: começa da direita
                y: innerRadius,
                width: activeWidth,
                height: barLength
            )
            
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: configuration.cornerRadius)
            configuration.activeColor.setFill()
            barPath.fill()
            
            context.restoreGState()
        }
        
        if activePercentage < 1.0 {
            // Parte INATIVA - o que sobrou na ESQUERDA
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: angle)
            
            let inactiveWidth = barWidthDegrees * (1.0 - activePercentage)
            
            let barRect = CGRect(
                x: -barWidthDegrees / 2,  // ← Começa da esquerda total
                y: innerRadius,
                width: inactiveWidth,
                height: barLength
            )
            
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: configuration.cornerRadius)
            configuration.inactiveColor.setFill()
            barPath.fill()
            
            context.restoreGState()
        }
    }
    
    // MARK: - Helper Methods
    
    private func drawRotatedBar(
        context: CGContext,
        center: CGPoint,
        angle: CGFloat,
        innerRadius: CGFloat,
        barLength: CGFloat,
        barWidth: CGFloat,
        color: UIColor,
        cornerRadius: CGFloat
    ) {
    
        context.saveGState()
        
        // Transladar para o centro
        context.translateBy(x: center.x, y: center.y)
        
        // Rotacionar para o ângulo correto
        context.rotate(by: angle)
        
        // Desenhar retângulo com origem no raio interno
        // O retângulo vai de innerRadius até innerRadius + barLength
        let barRect = CGRect(
            x: -barWidth / 2,
            y: innerRadius,
            width: barWidth,
            height: barLength
        )
        
        // Criar path com cantos arredondados
        let path = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius)
        
        // Preencher
        color.setFill()
        path.fill()
        
        context.restoreGState()
    }
    
    // MARK: - Color Animation
    
    /// Animate color change
    /// - Parameters:
    ///   - activeColor: New active color
    ///   - inactiveColor: New inactive color
    ///   - duration: Animation duration
    public func animateColors(activeColor: UIColor, inactiveColor: UIColor, duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.configuration.activeColor = activeColor
            self.configuration.inactiveColor = inactiveColor
            self.setNeedsDisplay()
        }
    }
}
