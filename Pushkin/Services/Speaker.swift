//
//  Speaker.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import AVFoundation

final class Speaker {
    let speechSynthesizer = AVSpeechSynthesizer()

    func speak(text: String) {
        speechSynthesizer.stopSpeaking(at: .word)
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
        let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Milena-premium") ?? AVSpeechSynthesisVoice(language: "ru-RU")
        speechUtterance.voice = voice
        speechUtterance.postUtteranceDelay = 1
        self.speechSynthesizer.speak(speechUtterance)
    }

    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
