# TiWaveform

A powerful Titanium module for audio waveform visualization and recording on iOS. Display beautiful waveforms for audio playback and real-time recording with extensive customization options.

![Titanium](https://img.shields.io/badge/Titanium-13.0+-red.svg) ![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg) ![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)

### Looking for the Android solution?
-  Ti.Waveform for Android by [Michael Gangolf](https://github.com/m1ga) [https://github.com/m1ga/ti.waveform](https://github.com/m1ga/ti.waveform)


## Features

### Waveform Visualization
- ✅ **Linear waveform** - Traditional horizontal bar visualization
- ✅ **Circular waveform** - Modern radial visualization
- ✅ **Two animation modes** - RADIAL (inside-out) and FLOW (angular sweep)
- ✅ **Smooth animations** - Fluid progress updates with easing
- ✅ **Full customization** - Colors, sizes, spacing, corner radius

### Audio Support
- ✅ **Multiple formats** - MP3, M4A, WAV, AAC, OPUS, OGG
- ✅ **WhatsApp audio** - Native support for OPUS voice messages
- ✅ **Telegram audio** - Native support for OGG files
- ✅ **Real-time recording** - Live waveform during audio capture

### Recording Features
- ✅ **Live visualization** - See waveform as you record
- ✅ **Pause/Resume** - Control recording state
- ✅ **Smooth animations** - Bars grow/shrink naturally during recording
- ✅ **Dynamic normalization** - Adapts to audio level changes

<p align="center">
  <img src="https://github.com/deckameron/Ti.Waveform/blob/main/assets/waveform.png?raw=true"
       width="300"
       alt="Example" />
</p>

## Requirements

- Titanium SDK 13.0.0+

## Installation

### 1. Download the Module

Download the latest version from the [releases page](https://github.com/deckameron/Ti.Waveform/releases).


### 2. Install the module in your Titanium project

```bash
# Copy the compiled module to:
{YOUR_PROJECT}/modules/iphone/
```

### 3. Configure tiapp.xml

Add the module to your `tiapp.xml`:

```xml
<modules>
    <module platform="iphone">ti.waveform</module>
</modules>
```

### Permissions

Add microphone permission to `tiapp.xml` for recording:

```xml
<ios>
    <plist>
        <dict>
            <key>NSMicrophoneUsageDescription</key>
            <string>This app needs microphone access to record audio</string>
        </dict>
    </plist>
</ios>
```

## Quick Start

### Basic Linear Waveform

```javascript
const TiWaveform = require('ti.waveform');

const waveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_LINEAR,
    height: 60,
    barWidth: 3,
    barSpacing: 2,
    activeColor: '#007AFF',
    inactiveColor: '#E5E5E5'
});

waveform.loadAudio({
    audioSource: '/path/to/audio.mp3',
    maxBarCount: 200
});

win.add(waveform);
```

### Basic Circular Waveform

```javascript
const TiWaveform = require('ti.waveform');

const waveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_CIRCULAR,
    width: 200,
    height: 200,
    barWidth: 4,
    barSpacing: 4,
    activeColor: '#FF3B30',
    inactiveColor: '#FFE5E5',
    circularAnimationType: TiWaveform.CIRCULAR_ANIMATION_RADIAL
});

waveform.loadAudio({
    audioSource: '/path/to/audio.mp3',
    maxBarCount: 100
});

win.add(waveform);
```

## API Reference

### Constants

#### Waveform Modes
- `MODE_LINEAR` - Horizontal bar visualization
- `MODE_CIRCULAR` - Radial circular visualization

#### Circular Animation Types
- `CIRCULAR_ANIMATION_RADIAL` - Bars fill from inside to outside
- `CIRCULAR_ANIMATION_FLOW` - Bars fill following the circular motion

### Properties

#### Common Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `mode` | Number | Visualization mode | MODE_LINEAR |
| `barWidth` | Number | Width of each bar in pixels/degrees | 3 |
| `barSpacing` | Number | Space between bars in pixels/degrees | 2 |
| `cornerRadius` | Number | Corner radius for rounded bars | 1.5 |
| `activeColor` | String | Color for played/active portion | '#007AFF' |
| `inactiveColor` | String | Color for unplayed/inactive portion | '#E5E5E5' |
| `minAmplitude` | Number | Minimum amplitude scaling factor | 0.4 |
| `maxAmplitude` | Number | Maximum amplitude scaling factor | 1.2 |
| `silenceThreshold` | Number | Threshold below which bars appear minimal | 0.05 |
| `scrubbingEnabled` | Boolean | Enable touch scrubbing (linear only) | true |

#### Linear Mode Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `minBarHeight` | Number | Minimum bar height in pixels | 4 |
| `maxBarHeight` | Number | Maximum bar height in pixels | view height |

#### Circular Mode Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `innerRadiusRatio` | Number | Inner circle size (0.0-1.0) | 0.3 |
| `minRadiusAmplitude` | Number | Minimum radial amplitude | 0.1 |
| `maxRadiusAmplitude` | Number | Maximum radial amplitude | 1.0 |
| `circularAnimationType` | Number | Animation style (RADIAL or FLOW) | RADIAL |

### Methods

#### `loadAudio(params)`

Load an audio file for visualization.

**Parameters:**
```javascript
{
    audioSource: String,  // File path (required)
    maxBarCount: Number   // Number of bars to display (optional, default: 200)
}
```

**Example:**
```javascript
waveform.loadAudio({
    audioSource: Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, 'audio.mp3').nativePath,
    maxBarCount: 150
});
```

#### `setProgress(progress, animated)`

Update playback progress.

**Parameters:**
- `progress` (Number) - Progress value from 0.0 to 1.0
- `animated` (Boolean) - Whether to animate the change

**Example:**
```javascript
waveform.setProgress(0.5, true);
```

#### `startRecording()`

Start audio recording with live waveform visualization.

#### `stopRecording()`

Stop audio recording.

#### `pauseRecording()`

Pause recording (can be resumed).

#### `resumeRecording()`

Resume paused recording.

#### `clear()`

Clear the waveform display.

#### `updateColors(params)`

Update waveform colors with optional animation.

**Parameters:**
```javascript
{
    active: String,    // Active color (optional)
    inactive: String,  // Inactive color (optional)
    animated: Boolean  // Animate color change (optional, default: true)
}
```

**Example:**
```javascript
waveform.updateColors({
    active: '#FF3B30',
    inactive: '#FFE5E5',
    animated: true
});
```

### Events

#### `loadingComplete`

Fired when audio file loading and processing is complete.

#### `seek`

Fired when user scrubs/seeks through the waveform (linear mode only).

**Event Properties:**
- `progress` (Number) - New progress position (0.0-1.0)

#### `recordingStarted`

Fired when recording begins.

#### `recordingStopped`

Fired when recording stops.

#### `recordingpaused`

Fired when recording is paused.

#### `recordingresumed`

Fired when recording is resumed.

#### `error`

Fired when an error occurs.

**Event Properties:**
- `message` (String) - Error description

## Complete Examples

### Audio Player with Linear Waveform

```javascript
const TiWaveform = require('ti.waveform');
const audioPlayer = Ti.Media.createAudioPlayer({
    url: '/path/to/song.mp3'
});

const waveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_LINEAR,
    top: 100,
    left: 20,
    right: 20,
    height: 60,
    barWidth: 3,
    barSpacing: 2,
    cornerRadius: 2,
    activeColor: '#007AFF',
    inactiveColor: '#E5E5E5',
    minBarHeight: 4,
    maxBarHeight: 60,
    scrubbingEnabled: true
});

waveform.loadAudio({
    audioSource: audioPlayer.url,
    maxBarCount: 200
});

audioPlayer.addEventListener('progress', function(e) {
    const progress = e.progress / audioPlayer.duration;
    waveform.setProgress(progress, false);
});

waveform.addEventListener('seek', function(e) {
    audioPlayer.setTime(e.progress * audioPlayer.duration);
});

const playButton = Ti.UI.createButton({
    title: 'Play',
    top: 180
});

playButton.addEventListener('click', function() {
    if (audioPlayer.playing) {
        audioPlayer.pause();
        playButton.title = 'Play';
    } else {
        audioPlayer.start();
        playButton.title = 'Pause';
    }
});

win.add([waveform, playButton]);
```

### Voice Recorder with Circular Waveform

```javascript
const TiWaveform = require('ti.waveform');

const waveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_CIRCULAR,
    width: 250,
    height: 250,
    barWidth: 4,
    barSpacing: 3,
    cornerRadius: 2,
    activeColor: '#FF3B30',
    inactiveColor: '#FFD5D5',
    innerRadiusRatio: 0.4,
    minRadiusAmplitude: 0.1,
    maxRadiusAmplitude: 1.0,
    circularAnimationType: TiWaveform.CIRCULAR_ANIMATION_FLOW
});

let isRecording = false;
let isPaused = false;

const recordButton = Ti.UI.createButton({
    title: 'Start Recording',
    bottom: 100,
    width: 200,
    height: 50
});

const pauseButton = Ti.UI.createButton({
    title: 'Pause',
    bottom: 40,
    width: 200,
    height: 50,
    enabled: false
});

recordButton.addEventListener('click', function() {
    if (!isRecording) {
        waveform.startRecording();
        recordButton.title = 'Stop Recording';
        pauseButton.enabled = true;
        isRecording = true;
    } else {
        waveform.stopRecording();
        recordButton.title = 'Start Recording';
        pauseButton.enabled = false;
        isRecording = false;
        isPaused = false;
    }
});

pauseButton.addEventListener('click', function() {
    if (!isPaused) {
        waveform.pauseRecording();
        pauseButton.title = 'Resume';
        isPaused = true;
    } else {
        waveform.resumeRecording();
        pauseButton.title = 'Pause';
        isPaused = false;
    }
});

win.add([waveform, recordButton, pauseButton]);
```

### WhatsApp Audio Player

```javascript
const TiWaveform = require('ti.waveform');
const whatsappAudioPath = '/path/to/whatsapp-audio.opus';

const waveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_LINEAR,
    top: 50,
    left: 20,
    right: 20,
    height: 50,
    barWidth: 2,
    barSpacing: 1,
    cornerRadius: 1,
    activeColor: '#25D366',
    inactiveColor: '#DCF8C6',
    minBarHeight: 3,
    maxBarHeight: 50
});

const audioPlayer = Ti.Media.createAudioPlayer({
    url: whatsappAudioPath
});

waveform.loadAudio({
    audioSource: whatsappAudioPath,
    maxBarCount: 150
});

audioPlayer.addEventListener('progress', function(e) {
    waveform.setProgress(e.progress / audioPlayer.duration, false);
});

waveform.addEventListener('seek', function(e) {
    audioPlayer.setTime(e.progress * audioPlayer.duration);
});

win.add(waveform);
```

## Troubleshooting

### Audio file not loading

**Problem:** Waveform stays empty after loading audio.

**Solutions:**
- ✅ Verify file path is correct and file exists
- ✅ Check file format is supported
- ✅ Listen for `error` event to see specific error message

```javascript
waveform.addEventListener('error', function(e) {
    console.error('Error loading audio: ' + e.message);
});
```

### Recording not working

**Problem:** Recording doesn't start or shows error.

**Solutions:**
- ✅ Add `NSMicrophoneUsageDescription` to tiapp.xml
- ✅ Request microphone permission before recording
- ✅ Ensure no other app is using microphone

### Waveform appears blank

**Problem:** View renders but no bars visible.

**Solutions:**
- ✅ Check color contrast with background
- ✅ Verify bar height/radius settings
- ✅ Ensure audio file has content (not silent)
- ✅ Try increasing `maxAmplitude` value

### Progress not updating smoothly

**Problem:** Progress jumps or stutters during playback.

**Solution:** Throttle progress updates

```javascript
let lastUpdate = 0;
audioPlayer.addEventListener('progress', function(e) {
    const now = Date.now();
    if (now - lastUpdate > 100) {
        waveform.setProgress(e.progress / audioPlayer.duration, true);
        lastUpdate = now;
    }
});
```

## Technical Details

### Supported Audio Formats

| Format | Extension | Support |
|--------|-----------|---------|
| MP3 | .mp3 | ✅ Native |
| AAC | .m4a, .aac | ✅ Native |
| WAV | .wav | ✅ Native |
| OPUS | .opus | ✅ Native (iOS 13+) |
| OGG | .ogg | ✅ Native (iOS 13+) |

### Performance

- **Memory Usage:** ~2-5 MB per waveform instance
- **CPU Usage:** Negligible after initial load
- **Animation:** 60 FPS smooth rendering

### Architecture

Built using:
- **AVFoundation** for audio decoding
- **Accelerate framework** for DSP operations
- **Core Graphics** for rendering
- **CADisplayLink** for smooth animations


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request