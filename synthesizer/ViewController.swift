//import UIKit
//import PDFKit
//import AVFoundation
//
//class ViewController: UIViewController, UIDocumentPickerDelegate {
//    var synthesizer = AVSpeechSynthesizer()
//    var utterance: AVSpeechUtterance?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let speakButton = UIButton(frame: CGRect(x: 100, y: 50, width: 200, height: 50))
//        speakButton.setTitle("Speak", for: .normal)
//        speakButton.backgroundColor = .blue
//        speakButton.addTarget(self, action: #selector(speakButtonPressed), for: .touchUpInside)
//        self.view.addSubview(speakButton)
//
//        let stopButton = UIButton(frame: CGRect(x: 100, y: 120, width: 200, height: 50))
//        stopButton.setTitle("Stop", for: .normal)
//        stopButton.backgroundColor = .red
//        stopButton.addTarget(self, action: #selector(stopButtonPressed), for: .touchUpInside)
//        self.view.addSubview(stopButton)
//
//        let selectPDFButton = UIButton(frame: CGRect(x: 20, y: 190, width: 200, height: 50))
//        selectPDFButton.setTitle("Select PDF", for: .normal)
//        selectPDFButton.backgroundColor = .gray
//        selectPDFButton.addTarget(self, action: #selector(selectPDFButtonPressed), for: .touchUpInside)
//        self.view.addSubview(selectPDFButton)
//    }
//
//    @objc func speakButtonPressed() {
//        if synthesizer.isSpeaking {
//            synthesizer.stopSpeaking(at: .immediate)
//        }
//        if let utterance = self.utterance {
//            synthesizer.speak(utterance)
//        }
//    }
//
//    @objc func stopButtonPressed() {
//        if synthesizer.isSpeaking {
//            synthesizer.stopSpeaking(at: .immediate)
//        }
//    }
//
//    @objc func selectPDFButtonPressed() {
//        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
//        documentPicker.delegate = self
//        present(documentPicker, animated: true, completion: nil)
//    }
//
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        if let sourceURL = urls.first {
//            do {
//                let fileName = sourceURL.lastPathComponent
//                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//                let destinationURL = documentsURL.appendingPathComponent(fileName)
//                
//                // Remove existing file at destination URL if it exists
//                if FileManager.default.fileExists(atPath: destinationURL.path) {
//                    try FileManager.default.removeItem(at: destinationURL)
//                }
//                
//                // Copy file from sourceURL to the destinationURL
//                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
//                
//                // Now you can create the PDFDocument using destinationURL and create the AVSpeechUtterance
////                if let pdfDocument = PDFDocument(url: destinationURL), let textToSpeak = pdfDocument.string {
////                    self.utterance = AVSpeechUtterance(string: textToSpeak)
////                    self.utterance?.voice = AVSpeechSynthesisVoice(language: "ru-RU")
////                }
//                
//            } catch {
//                print("Failed to copy file: \(error.localizedDescription)")
//            }
//        }
//    }
//
//}
