import UIKit
import PDFKit
import AVFoundation
import AudioKit
import AudioKitUI

extension Float {
    func rounded(toPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}
class PDFViewerViewController: UIViewController,AVSpeechSynthesizerDelegate {
    var currentTextPosition: Int = 0
    var totalTextLength: Int = 0
    var totalSpeechDuration: TimeInterval = 0
    var currentSpeechTime: TimeInterval = 0
    var lastSpokenTextRange: NSRange = NSRange(location: 0, length: 0)
    var timer: Timer?
    var lastUpdateTime: Date?
    var speechSlider: UISlider!
    var timeLabel: UILabel!
    var speedButton: UIButton!
    var utterance: AVSpeechUtterance!
    var isSliderChangeFromUser = false
    var progr:Float = 0
    let speechButton = UIButton(type: .system)
    let speechSynthesizer = AVSpeechSynthesizer()
    let fileURL: URL
    let textView = UITextView()
    var fontSize: CGFloat = 14.0 // Устанавливаем начальный размер шрифта
    var synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false
    var lastPausedPosition: AVSpeechUtterance?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupSpeechControls()
        calculateTotalSpeechDuration()
        startSpeechSynthesis()
        setupAudioSession()
        speechButton.setTitle("Speak", for: .normal)
        speechButton.addTarget(self, action: #selector(handleSpeechButtonPressed), for: .touchUpInside)
        synthesizer.delegate = self
        speechButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speechButton)
        NSLayoutConstraint.activate([
            speechButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speechButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10
                                             )
        ])
    }
    
    @objc func handleSpeechButtonPressed() {
        if synthesizer.isSpeaking {
            if isSpeaking {
                synthesizer.pauseSpeaking(at: .word)
                isSpeaking = false
            } else {
                synthesizer.continueSpeaking()
                isSpeaking = true
            }
        } else {
            speakFromCurrentPosition()
            isSpeaking = true
        }
    }
    
    func speakFromCurrentPosition() {
        let startIndex = textView.text.index(textView.text.startIndex, offsetBy: currentTextPosition)
        let substring = String(textView.text[startIndex...])
        configureUtterance(from: substring)
    }
    
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        lastPausedPosition = utterance
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        lastPausedPosition = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        lastPausedPosition = nil
    }
    func startSpeechSynthesis() {
        totalTextLength = textView.text.filter { !$0.isWhitespace }.count
        lastUpdateTime = Date()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }
    
    
    func calculateTotalSpeechDuration() {
        let rate = 0.5
        let wordsPerMinute = 60 / (rate / 100)
        let totalWords = textView.text.split { $0.isWhitespace }.count
        totalSpeechDuration = TimeInterval(totalWords) / Double(wordsPerMinute)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        if isSliderChangeFromUser {
            DispatchQueue.main.async { [self] in
                self.synthesizer.stopSpeaking(at: .immediate)
                currentTextPosition = Int(sender.value * Float(totalTextLength) / 100)
                print(self.currentTextPosition,"===")
                speakFromCurrentPosition()
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        self.lastSpokenTextRange = characterRange
        self.lastUpdateTime = Date()
        self.updateSlider()
    }
    
    func stopReading() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        timer?.invalidate()
        timer = nil
    }
    
    func positionExcludingSpaces(for position: Int, in text: String) -> Int {
        let textWithoutSpaces = text.prefix(position).filter { !$0.isWhitespace }
        return textWithoutSpaces.count
    }
    
    @objc func updateSlider() {
        guard let lastUpdateTime = self.lastUpdateTime else { return }
        let elapsedTime = Date().timeIntervalSince(lastUpdateTime)
        let wordsPerSecond = 1.0 / 0.5
        let averageCharactersPerWord = 10
        let additionalCharacters = Double(wordsPerSecond * Double(averageCharactersPerWord) * elapsedTime)
        self.currentTextPosition = self.currentTextPosition + Int(additionalCharacters)
        let sliderValue = Float(self.currentTextPosition) / Float(self.textView.text.filter { !$0.isWhitespace }.count)
        self.speechSlider.setValue(sliderValue * 100, animated: true)
    }
    
    @objc func sliderTouchBegan(_ sender: UISlider) {
        isSliderChangeFromUser = true
    }
    
    @objc func sliderTouchEnded(_ sender: UISlider) {
        isSliderChangeFromUser = false
    }
    
    @objc func changeSpeed(_ sender: UIButton) {
        let currentRate = utterance.rate
        let newRate = min(max(currentRate + 0.02, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.rate = newRate
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            speakFromCurrentPosition()
        }
        speedButton.setTitle("\(newRate.rounded(toPlaces: 2))x", for: .normal)
    }
    
    func configureUtterance(from text: String) {
        utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5 // Установите нужную скорость
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        synthesizer.speak(utterance)
    }
    
    func setupSpeechControls() {
        speechSlider = UISlider(frame: CGRect(x: 0, y: 100, width: 200, height: 40))
        speechSlider.minimumValue = 0
        speechSlider.maximumValue = 100
        speechSlider.value = 0
        speechSlider.isContinuous = true
        speechSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        speechSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside])
        view.addSubview(speechSlider)
        timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        timeLabel.text = "00:00"
        view.addSubview(timeLabel)
        speedButton = UIButton(type: .system)
        speedButton.setTitle("1x", for: .normal)
        speedButton.addTarget(self, action: #selector(changeSpeed(_:)), for: .touchUpInside)
        view.addSubview(speedButton)
        speechSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    func speakTextChunk() {
        let text = textView.text ?? ""
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Milena-compact")
        
        synthesizer.speak(utterance)
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession.setActive(true)
            NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: audioSession)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }
    
    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
        } else if type == .ended {
        }
    }
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU") 
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func setupView() {
        textView.frame = view.bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.isEditable = false
        
        if let document = PDFDocument(url: fileURL),
           let text = document.string {
            textView.text = text
            textView.font = UIFont.systemFont(ofSize: fontSize)
        } else {
            print("Could not create document from URL: \(fileURL)")
        }
        
        let zoomInButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(zoomIn))
        let zoomOutButton = UIBarButtonItem(image: UIImage(systemName: "minus"), style: .plain, target: self, action: #selector(zoomOut))
        navigationItem.rightBarButtonItems = [zoomInButton, zoomOutButton]
        view.addSubview(textView)
    }
    
    @objc func zoomIn() {
        fontSize += 1
        textView.font = UIFont.systemFont(ofSize: fontSize)
    }
    
    @objc func zoomOut() {
        if fontSize > 1 {
            fontSize -= 1
            textView.font = UIFont.systemFont(ofSize: fontSize)
        }
    }
}
