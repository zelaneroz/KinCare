import AVFoundation
import Combine
import Speech

@MainActor
final class SpeechInputService: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasInstalledTap = false

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func startRecording() async {
        errorMessage = nil

        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            errorMessage = "Allow Speech Recognition in Settings to dictate a care task."
            return
        }

        let microphoneAllowed = await requestMicrophoneAuthorization()
        guard microphoneAllowed else {
            errorMessage = "Allow Microphone access in Settings to dictate a care task."
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is temporarily unavailable."
            return
        }

        stopRecording()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: format
        ) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        hasInstalledTap = true

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }

                    if error != nil || result?.isFinal == true {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            stopRecording()
            errorMessage = "KinCare could not start listening. \(error.localizedDescription)"
        }
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
