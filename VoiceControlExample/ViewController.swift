//
//  ViewController.swift
//  VoiceControlExample
//
//  Created by Germán Stábile on 6/10/20.
//  Copyright © 2020 Rootstrap. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  fileprivate lazy var listeningLabel: UILabel = self.buildLabel(
    with: "I can't hear you, please activate Voice Control.",
    fontSize: 20
  )
  
  fileprivate lazy var counterLabel: UILabel = self.buildLabel(with: "0", fontSize: 40)
  
  fileprivate lazy var activateVoiceControlButton: UIButton = self.buildButton()
  
  fileprivate var currentCount = 0

  //MARK: View Controller Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
  }
  
  //MARK: Layout
  fileprivate func configureViews() {
    view.backgroundColor = .white
    view.addSubview(counterLabel)
    view.addSubview(activateVoiceControlButton)
    view.addSubview(listeningLabel)
    
    activateConstraints()
  }
  
  fileprivate func activateConstraints() {
    NSLayoutConstraint.activate([
      listeningLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
      listeningLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
      listeningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      
      counterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      
      activateVoiceControlButton.widthAnchor.constraint(equalToConstant: 250),
      activateVoiceControlButton.heightAnchor.constraint(equalToConstant: 50),
      activateVoiceControlButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activateVoiceControlButton.bottomAnchor.constraint(
        equalTo: view.bottomAnchor, constant: -100
      )
    ])
  }
  
  fileprivate func buildLabel(with text: String, fontSize: CGFloat) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: fontSize)
    label.text = text
    label.textColor = .black
    label.numberOfLines = 0
    label.textAlignment = .center
    
    return label
  }
  
  fileprivate func buildButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.clipsToBounds = true
    button.layer.cornerRadius = 8
    button.backgroundColor = .darkGray
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    button.setTitleColor(.white, for: .normal)
    button.setTitle("Activate Voice Control", for: .normal)
    button.addTarget(
      self,
      action: #selector(activateVoiceControlButtonTapped),
      for: .touchUpInside
    )
    
    return button
  }
  
  //MARK: Actions
  @objc
  func activateVoiceControlButtonTapped() {
    VoiceControlManager.shared.startListening(with: self)
    updateUI(isListening: true)
  }
  
  fileprivate func updateCount() {
    counterLabel.text = "\(currentCount)"
  }
  
  fileprivate func updateUI(isListening: Bool) {
    activateVoiceControlButton.isEnabled = !isListening
    activateVoiceControlButton.alpha = isListening ? 0.5 : 1
    
    listeningLabel.text = isListening ?
      "I'm listening, say Increase Count or Decrease Count to update counter. Say Stop Listening when you are done." : "I can't hear you, please activate Voice Control."
  }
}

extension ViewController: VoiceControlResponder {
  func authorizationDenied() {
    print("auth denied")
  }
  
  func speechRecognizerFailed() {
    print("recognizer failed")
  }
  
  func recognized(speech: String) {
    switch speech {
    case "Increase Count":
      currentCount += 1
      updateCount()
    case "Decrease Count":
      currentCount -= 1
      updateCount()
    default:
      break
    }
    
    //after recognizing speech VCManager stops listening
    //so if the speech isn't Stop Listening we start again
    if speech != "Stop Listening" {
      VoiceControlManager.shared.startListening(with: self)
    } else {
      updateUI(isListening: false)
    }
  }
  
  func expectedSpeeches() -> [String] {
    return ["Increase Count", "Decrease Count", "Stop Listening"]
  }
}
