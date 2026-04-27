import Foundation
import AVFoundation
import Speech
import Observation

/// Wraps SFSpeechRecognizer + AVAudioEngine for streaming on-device transcription.
@MainActor
@Observable
final class SpeechRecognizer {
    enum Status { case idle, requesting, denied, recording, error }

    var status: Status = .idle
    var transcript: String = ""
    /// 0…1 audio level — used to drive the waveform animation.
    var audioLevel: Float = 0

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        let speechOk = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechOk else { return false }
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in cont.resume(returning: granted) }
        }
    }

    func start() async {
        if status == .recording { return }
        status = .requesting
        let granted = await requestPermissions()
        guard granted else { status = .denied; return }
        guard let recognizer, recognizer.isAvailable else { status = .error; return }

        // Audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            status = .error
            return
        }

        let engine = AVAudioEngine()
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = false
        if #available(iOS 16, *) { req.addsPunctuation = true }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            req.append(buffer)
            // RMS level for waveform animation
            if let channel = buffer.floatChannelData?[0] {
                let n = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<n { sum += channel[i] * channel[i] }
                let rms = sqrt(sum / Float(max(n, 1)))
                let normalized = min(max(rms * 8, 0), 1)
                Task { @MainActor in self?.audioLevel = normalized }
            }
        }

        engine.prepare()
        do { try engine.start() } catch { status = .error; return }

        let task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.cleanup()
                }
            }
        }

        self.audioEngine = engine
        self.request = req
        self.task = task
        self.status = .recording
    }

    func stop() {
        cleanup()
    }

    private func cleanup() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if status == .recording { status = .idle }
        audioLevel = 0
    }
}
