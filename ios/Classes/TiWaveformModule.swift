//
//  TiWaveformModule.swift
//  TiWaveform
//
//  Main Titanium SDK module
//

import UIKit
import TitaniumKit
import AVFAudio

@objc(TiWaveformModule)
class TiWaveformModule: TiModule {
    
    // MARK: - Module Lifecycle
    
    func moduleGUID() -> String {
        return "ti.waveform"
    }
    
    func moduleName() -> String {
        return "Ti.Waveform"
    }
    
    override func startup() {
        super.startup()
        debugPrint("[Ti.Waveform] Module loaded")
    }
    
    // MARK: - Constants
    
    @objc(MODE_LINEAR)
    var MODE_LINEAR: Int {
        return 0
    }
    
    @objc(MODE_CIRCULAR)
    var MODE_CIRCULAR: Int {
        return 1
    }
    
    @objc(STATE_IDLE)
    var STATE_IDLE: Int {
        return 0
    }
    
    @objc(STATE_LOADING)
    var STATE_LOADING: Int {
        return 1
    }
    
    @objc(STATE_READY)
    var STATE_READY: Int {
        return 2
    }
    
    @objc(STATE_PLAYING)
    var STATE_PLAYING: Int {
        return 3
    }
    
    @objc(STATE_RECORDING)
    var STATE_RECORDING: Int {
        return 4
    }
    
    @objc(STATE_ERROR)
    var STATE_ERROR: Int {
        return 5
    }
    
    // MARK: - Public Methods (Module-level)
    
    /// Get module version
    @objc(version:)
    func version(_ args: [Any]?) -> String {
        return "1.0.0"
    }
    
    @objc(isAudioFileSupported:)
    func isAudioFileSupported(arguments: Array<Any>?) -> Bool {
        guard let filePath = arguments?.first as? String else {
            return false
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        // Verificar se arquivo existe
        guard FileManager.default.fileExists(atPath: filePath) else {
            return false
        }
        
        // Verificar se AVAudioFile consegue abrir
        do {
            _ = try AVAudioFile(forReading: url)
            return true
        } catch {
            return false
        }
    }
    
    /// Create a waveform view
    @objc(createWaveformView:)
    func createWaveformView(_ args: [Any]?) -> TiWaveformViewProxy {
        var properties: [String: Any] = [:]
        if let args = args, !args.isEmpty {
            if let dict = args[0] as? [String: Any] {
                properties = dict
            }
        }
        
        let proxy = TiWaveformViewProxy()
        proxy._init(withProperties: properties)
        return proxy
    }
    
    @objc public let CIRCULAR_ANIMATION_RADIAL = 0
    @objc public let CIRCULAR_ANIMATION_FLOW = 1
}
