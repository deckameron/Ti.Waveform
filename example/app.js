//
//  Example App - TiWaveform Complete Demo
//  Demonstrates all module features
//

const TiWaveform = require('ti.waveform');

const win = Ti.UI.createWindow({
    backgroundColor: '#f5f5f5',
    title: 'TiWaveform Demo'
});

const scrollView = Titanium.UI.createScrollView({
    top: 0,
    layout: "vertical"
});
win.add(scrollView);

// ============================================
// EXAMPLE 1: Basic Playback Waveform
// ============================================

const section1Label = Ti.UI.createLabel({
    text: 'Basic Playback',
    top: 16,
    left: 20,
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333'
});
scrollView.add(section1Label);

const playbackWaveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_LINEAR,
    height: 60,
    top: 24,
    left: 20,
    right: 20,
    minBarHeight: 4,
    maxBarHeight: 60, 
    barWidth: 4,
    barSpacing: 6,
    cornerRadius: 2,
    activeColor: '#007AFF',
    inactiveColor: '#E5E5E5',
    scrubbingEnabled: true
});

playbackWaveform.addEventListener('loadingComplete', () => {
    Ti.API.info('Playback waveform loaded');
    statusLabel.text = 'Ready to play';
});

const audio_source = Ti.Filesystem.resourcesDirectory + 'assets/audio/design_aesthetics.mp3'

const audioPlayer = Titanium.Media.createAudioPlayer({
    url: "/assets/audio/design_aesthetics.mp3",
    allowBackground: true
});

audioPlayer.addEventListener('error', (error)=>{
    console.log(error);
});

audioPlayer.addEventListener('change', function(e) {
    console.log('State: ' + e.description + ' (' + e.state + ')');
});

audioPlayer.addEventListener('progress', (ap)=>{
    console.warn("=========================================")
    console.log("Progress in ms: " + ap.progress);
    const formatted_percentage = ap.progress / audioPlayer.duration;
    console.log("Percentage: " + formatted_percentage);
    
    playbackWaveform.seekToProgress(formatted_percentage, true);
    circularWaveform.seekToProgress(formatted_percentage, true);
});

playbackWaveform.addEventListener('progress', (e) => {
    progressLabel.text = `Progress: ${(e.value * 100).toFixed(1)}%`;
    
    // In real app, sync with audio player here
    audioPlayer.time = e.value * audioPlayer.duration;
});

playbackWaveform.addEventListener('seek', function(e) {

    const progress = e.progress; // 0.0 a 1.0
    const time = (progress * audioPlayer.duration).toFixed(0);
    
    console.log("======== SEEK =========")
    console.log(`Seeked to: (${progress * 100}%)`);
    console.log("Audio duration: " + audioPlayer.duration);
    console.log("Time: " + time);
    
    // Atualizar seu audio player
    audioPlayer.seekToTime(progress * audioPlayer.duration);
});

playbackWaveform.loadAudio({
    "audioSource": audio_source, 
    "maxBarCount": 200
});
scrollView.add(playbackWaveform);

// Status labels
const statusLabel = Ti.UI.createLabel({
    text: 'Loading...',
    top: 24,
    left: 20,
    font: { fontSize: 14 },
    color: '#666'
});
scrollView.add(statusLabel);

const progressLabel = Ti.UI.createLabel({
    text: 'Progress: 0%',
    top: 16,
    left: 20,
    font: { fontSize: 14, fontWeight: "bold" },
    color: '#3f3f3f'
});
scrollView.add(progressLabel);

const buttonsWrapper = Titanium.UI.createView({
    top: 24,
    left: 20,
    right: 16,
    layout: "horizontal",
    height: Titanium.UI.SIZE
});
scrollView.add(buttonsWrapper);

// Control buttons
const playButton = Ti.UI.createButton({
    title: 'Play / Pause',
    color: "#FFF",
    backgroundColor: "rgb(67, 67, 220)",
    borderRadius: 10,
    width: 100,
    height: 40
});
buttonsWrapper.add(playButton);

playButton.addEventListener('click', (ap) => {
    console.log("audioPlayer.playing: " + audioPlayer.playing);
    console.log("audioPlayer.paused: " + audioPlayer.paused);
    if (audioPlayer.playing) audioPlayer.pause();
    else if (audioPlayer.paused) audioPlayer.start();
    else audioPlayer.start();
});

const simulatePlayBtn = Ti.UI.createButton({
    title: 'Simulate Play',
    color: "#FFF",
    backgroundColor: "rgb(67, 67, 220)",
    borderRadius: 10,
    left: 16,
    width: 120,
    height: 40
});
buttonsWrapper.add(simulatePlayBtn);

simulatePlayBtn.addEventListener('click', () => {
    // Simulate playback progress
    let progress = 0;
    const interval = setInterval(() => {
        progress += 0.01;
        if (progress >= 1.0) {
            clearInterval(interval);
            progress = 1.0;
        }
        playbackWaveform.seekToProgress(progress, false);
    }, 50);
});

const resetBtn = Ti.UI.createButton({
    title: 'Reset',
    color: "#FFF",
    backgroundColor: "rgb(67, 67, 220)",
    borderRadius: 10,
    left: 16,
    width: 100,
    height: 40
});
buttonsWrapper.add(resetBtn);

resetBtn.addEventListener('click', () => {
    playbackWaveform.seekToProgress(0, true);
});

// ============================================
// EXAMPLE 2: Circular Waveform
// ============================================

const section2Label = Ti.UI.createLabel({
    text: 'Circular Waveform',
    top: 36,
    left: 20,
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333'
});
scrollView.add(section2Label);

const circularContainer = Ti.UI.createView({
    top: 24,
    width: 200,
    height: 200,
    borderRadius: 100
});
scrollView.add(circularContainer);

const circularWaveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_CIRCULAR,
    width: 200,
    height: 200,
    
    // Customizações completas!
    barWidth:4,           // Largura angular em graus
    barSpacing: 6,         // Espaçamento em graus
    cornerRadius: 2,       // Cantos arredondados
    
    innerRadiusRatio: 0.4, // 40% do raio externo
    minRadiusAmplitude: 0.1,
    maxRadiusAmplitude: 1.0,
    silenceThreshold: 0.05,
    backgroundColor: "transparent",
    circularAnimationType: TiWaveform.CIRCULAR_ANIMATION_FLOW,
    
    activeColor: '#FF3B30',
    inactiveColor: '#FFE5E5'
});

circularWaveform.loadAudio({
    "audioSource": audio_source, 
    "maxBarCount": 180
});
circularContainer.add(circularWaveform);

// ============================================
// EXAMPLE 3: Live Recording
// ============================================

const section3Label = Ti.UI.createLabel({
    text: 'Live Recording',
    top: 36,
    left: 20,
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333'
});
scrollView.add(section3Label);

const recordingWaveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_CIRCULAR,
    circularAnimationType: TiWaveform.CIRCULAR_ANIMATION_RADIAL,
    width: 200,
    height: 200,

    barWidth:4,           // Largura angular em graus
    barSpacing: 6,         // Espaçamento em graus
    cornerRadius: 2,       // Cantos arredondados
    
    innerRadiusRatio: 0.4, // 40% do raio externo
    minRadiusAmplitude: 0.1,
    maxRadiusAmplitude: 1.0,
    silenceThreshold: 0.05,

    activeColor: '#FF3B30',
    inactiveColor: '#FFE5E5',
    scrubbingEnabled: false
});
scrollView.add(recordingWaveform);

const recordingStatusLabel = Ti.UI.createLabel({
    text: 'Ready to record',
    top: 24,
    left: 20,
    font: { fontSize: 14 },
    color: '#666'
});
scrollView.add(recordingStatusLabel);

let isRecording = false;
const recordBtn = Ti.UI.createButton({
    title: 'Start Recording',
    top: 24,
    width: 150,
    height: 40,
    borderRadius: 10,
    backgroundColor: '#FF3B30',
    color: '#fff'
});

recordBtn.addEventListener('click', () => {
    if (!isRecording) {
        recordingWaveform.startRecording();
        recordBtn.title = 'Stop Recording';
        recordBtn.backgroundColor = '#666';
        isRecording = true;
        recordingStatusLabel.text = 'Recording...';
    } else {
        recordingWaveform.stopRecording();
        recordBtn.title = 'Start Recording';
        recordBtn.backgroundColor = '#FF3B30';
        isRecording = false;
        recordingStatusLabel.text = 'Recording stopped';
    }
});
scrollView.add(recordBtn);

recordingWaveform.addEventListener('recordingStarted', () => {
    Ti.API.info('Recording started');
});

recordingWaveform.addEventListener('recordingStopped', () => {
    Ti.API.info('Recording stopped');
});

// ============================================
// EXAMPLE 4: Dynamic Color Change
// ============================================

const section4Label = Ti.UI.createLabel({
    text: 'Dynamic Colors',
    top: 36,
    left: 20,
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333'
});
scrollView.add(section4Label);

const colorWaveform = TiWaveform.createWaveformView({
    mode: TiWaveform.MODE_LINEAR,
    width: Ti.UI.FILL,
    height: 50,
    top: 24,
    left: 20,
    right: 20
});
scrollView.add(colorWaveform);

colorWaveform.loadAudio({
    "audioSource": audio_source, 
    "maxBarCount": 150
});
colorWaveform.seekToProgress(0.5, false);

const colorsButtonsWrapper = Titanium.UI.createView({
    top: 24,
    left: 4,
    right: 16,
    layout: "horizontal",
    height: Titanium.UI.SIZE
});
scrollView.add(colorsButtonsWrapper);

const colorButtons = [
    { title: 'Blue', active: '#007AFF', inactive: '#E5E5E5', left: 20 },
    { title: 'Red', active: '#FF3B30', inactive: '#FFE5E5', left: 110 },
    { title: 'Green', active: '#34C759', inactive: '#E5F5E5', left: 200 }
];

colorButtons.forEach((config) => {

    const btn = Ti.UI.createButton({
        title: config.title,
        color: "#FFF",
        left: 16,
        backgroundColor: config.active,
        borderRadius: 10,
        width: 80,
        height: 35
    });
    colorsButtonsWrapper.add(btn)
    
    btn.addEventListener('click', () => {
        colorWaveform.updateColors({
            active: config.active,
            inactive: config.inactive,
            animated: true
        });
    });
});

// ============================================
// EXAMPLE 5: Multiple Waveforms (Playlist)
// ============================================

const section5Label = Ti.UI.createLabel({
    text: 'Playlist View (Click them!)',
    top: 36,
    left: 20,
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333'
});
scrollView.add(section5Label);

const wrapper_view = Ti.UI.createView({
    top: 16,
    width: Ti.UI.FILL,
    height: 250,
    contentHeight: 'auto'
});
scrollView.add(wrapper_view);

const playlist = [
    { file: 'assets/audio/design_aesthetics.mp3', title: 'Track 1', duration: '3:45', active: '#007AFF', barWidth: 2, barSpacing: 1 },
    { file: 'assets/audio/ocil.mp3', title: 'Track 2', duration: '2:30', active: '#FF3B30', barWidth: 3, barSpacing: 3 },
    { file: 'assets/audio/test.wav', title: 'Track 3', duration: '4:15', active: '#34C759', barWidth: 1, barSpacing: 4 }
];

playlist.forEach((track, index) => {

    const container = Ti.UI.createView({
        top: index * 70,
        width: Ti.UI.FILL,
        height: 60,
        backgroundColor: '#FFF',
        borderRadius: 8
    });
    
    const titleLabel = Ti.UI.createLabel({
        text: track.title,
        left: 10,
        top: 5,
        font: { fontSize: 14, fontWeight: 'bold' },
        color: '#333'
    });
    container.add(titleLabel);
    
    const durationLabel = Ti.UI.createLabel({
        text: track.duration,
        right: 10,
        top: 5,
        font: { fontSize: 12 },
        color: '#666'
    });
    container.add(durationLabel);
    
    const trackWaveform = TiWaveform.createWaveformView({
        mode: TiWaveform.MODE_LINEAR,
        width: Ti.UI.FILL,
        height: 30,
        top: 25,
        left: 10,
        right: 10,
        barWidth: track.barWidth,
        barSpacing: track.barSpacing,
        cornerRadius: 1,
        activeColor: track.active,
        inactiveColor: '#E5E5E5'
    });
    
    trackWaveform.loadAudio({
        "audioSource": Ti.Filesystem.resourcesDirectory + track.file, 
        "maxBarCount": 100
    });
    container.addEventListener('click', () => {
        // Simulate playing this track
        trackWaveform.seekToProgress(0, false);
        let progress = 0;
        const interval = setInterval(() => {
            progress += 0.02;
            if (progress >= 1.0) {
                clearInterval(interval);
            }
            trackWaveform.seekToProgress(progress, true);
        }, 100);
    });
    
    container.add(trackWaveform);
    wrapper_view.add(container);
});

// ============================================
// Error Handling
// ============================================

[playbackWaveform, circularWaveform, recordingWaveform, colorWaveform].forEach((waveform) => {
    waveform.addEventListener('error', (e) => {
        // Ti.UI.createAlertDialog({
        //     title: 'Error',
        //     message: e.message,
        //     buttonNames: ['OK']
        // }).show();
        console.log("[ERROR]", e.message);
    });
});

// ============================================
// Open Window
// ============================================

// Create tab or navigation
if (Ti.Platform.osname === 'iphone' || Ti.Platform.osname === 'ipad') {
    const nav = Ti.UI.createNavigationWindow({
        window: win
    });
    nav.open();
} else {
    win.open();
}

// ============================================
// Memory Management Demo
// ============================================

win.addEventListener('close', () => {
    Ti.API.info('Cleaning up waveforms...');
    
    // Clear all waveforms
    playbackWaveform.clear();
    circularWaveform.clear();
    recordingWaveform.clear();
    colorWaveform.clear();
    
    // Stop recording if active
    if (isRecording) {
        recordingWaveform.stopRecording();
    }
});