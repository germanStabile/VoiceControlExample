//
//  VoiceControlManager.swift
//  VoiceControlExample
//
//  Created by Germán Stábile on 6/10/20.
//  Copyright © 2020 Rootstrap. All rights reserved.
//

import Foundation
import Speech

protocol VoiceControlResponder: class {
  func authorizationDenied()
  func speechRecognizerFailed()
  func recognized(speech: String)
  func expectedSpeeches() -> [String]
}

class VoiceControlManager: NSObject {
  
  static let shared = VoiceControlManager()
  
  weak var delegate: VoiceControlResponder?
  
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine: AVAudioEngine?
  
  fileprivate override init() {} // we don't want other instances to be created.
  
  //MARK: Public functions
  func startListening(with delegate: VoiceControlResponder?) {
    self.delegate = delegate
    
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
      startListening()
    case .notDetermined:
      requestAuthorization()
    default:
      delegate?.authorizationDenied()
    }
  }
  
  func stopListening() {
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    recognitionTask?.cancel()
    recognitionTask?.finish()
    recognitionTask = nil 
    recognitionRequest?.endAudio()
    recognitionRequest = nil
  }
  
  //MARK: Private functions
  fileprivate func startListening() {
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    audioEngine = AVAudioEngine()
    
    guard
      let audioEngine = audioEngine,
      let recognitionRequest = recognitionRequest,
      let recognizer = SFSpeechRecognizer(),
      recognizer.isAvailable,
      let expectedSpeeches = delegate?.expectedSpeeches()
    else {
      self.delegate?.speechRecognizerFailed()
      return
    }
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.record)
      try audioSession.setMode(.measurement)
      try audioSession.setActive(
        true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation
      )
    } catch {
      delegate?.speechRecognizerFailed()
      print("audioSession properties weren't set because of an error.")
    }
    
    recognitionRequest.shouldReportPartialResults = true
    recognitionRequest.contextualStrings = expectedSpeeches
    recognitionTask = recognizer.recognitionTask(
      with: recognitionRequest,
      delegate: self
    )
    
    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(
      onBus: 0, bufferSize: 100, format: recordingFormat
    ) { [weak self] buffer, _ in
      self?.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    do {
      try audioEngine.start()
    } catch {
      delegate?.speechRecognizerFailed()
      print("audioEngine couldn't start because of an error.")
    }
  }
  
  fileprivate func requestAuthorization() {
    SFSpeechRecognizer.requestAuthorization { [weak self] status in
      switch status {
      case .authorized:
        self?.startListening()
      default:
        self?.delegate?.authorizationDenied()
      }
    }
  }
}

extension VoiceControlManager: SFSpeechRecognitionTaskDelegate {
  func speechRecognitionTask(
    _ task: SFSpeechRecognitionTask,
    didHypothesizeTranscription transcription: SFTranscription
  ) {
    print("we have an hypotesis: \(transcription.formattedString)")
    guard
      let expectedSpeeches = delegate?.expectedSpeeches(),
      let recognizedSpeech = expectedSpeeches.first(
        where: { transcription.formattedString.contains($0) }
      )
    else { return }
    
    stopListening()
    delegate?.recognized(speech: recognizedSpeech)
  }
}
