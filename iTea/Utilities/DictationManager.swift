import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
final class DictationManager {
    private(set) var isRecording = false
    private(set) var isAvailable = false
    private(set) var permissionDenied = false

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    /// Called with (transcription, isFinal) - replace text for partial results, commit on final
    var onTranscription: ((String, Bool) -> Void)?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        checkAvailability()
    }

    private func checkAvailability() {
        isAvailable = speechRecognizer?.isAvailable ?? false
    }

    func requestPermissions() async -> Bool {
        // Request speech recognition permission using detached task to avoid @MainActor isolation
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await Task.detached {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        }.value

        guard speechStatus == .authorized else {
            permissionDenied = true
            return false
        }

        // Request microphone permission
        let micStatus = await AVAudioApplication.requestRecordPermission()

        if !micStatus {
            permissionDenied = true
            return false
        }

        permissionDenied = false
        return true
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    func startRecording() async {
        guard !isRecording else { return }

        // Check permissions first
        let hasPermission = await requestPermissions()
        guard hasPermission else { return }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }

        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }

            recognitionRequest.shouldReportPartialResults = true

            // Use on-device recognition if available
            if speechRecognizer.supportsOnDeviceRecognition {
                recognitionRequest.requiresOnDeviceRecognition = true
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Mark closure as @Sendable to opt out of @MainActor isolation since this runs on audio thread
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { @Sendable buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        self.onTranscription?(transcription, result.isFinal)
                    }

                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            stopRecording()
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
