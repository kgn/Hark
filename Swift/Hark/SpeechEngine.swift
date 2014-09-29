//
//  SpeechEngine.swift
//  Hark
//
//  Created by David Keegan on 9/24/14.
//  Copyright (c) 2014 David Keegan. All rights reserved.
//

import AVFoundation

class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate {

    lazy var speechSynthesizer: AVSpeechSynthesizer = {
        let speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
        return speechSynthesizer
    }()

    func readText(text: String, voiceLanguage: String? = nil, rate: Float = 1, volume: Float = 1, pitchMultiplier: Float = 1) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitchMultiplier
        if let language = voiceLanguage {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        self.speechSynthesizer.speakUtterance(utterance)
    }

    func stopReading() {
        self.speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
    }

    func systemVoiceLanguage() -> String {
        let languageCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as String
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as String
        return "\(languageCode)-\(countryCode)"
    }

    func voiceLanguage(text: String) -> String {
        let cftext: CFString = text as NSString
        let range = CFRangeMake(0, min(400, countElements(text)))
        let currentLanguage = AVSpeechSynthesisVoice.currentLanguageCode()
        let language: NSString = CFStringTokenizerCopyBestStringLanguage(cftext, range)

        if !currentLanguage.hasPrefix(language) {
            var availableLanguages: [String] = []
            for l in AVSpeechSynthesisVoice.speechVoices() {
                availableLanguages.append(l.language)
            }
            if contains(availableLanguages, language) {
                return language
            }

            // TODO: also support Cantonese (zh-HK)
            // Language code translations for simplified and traditional Chinese
            if language == "zh-Hans" {
                return "zh-CN"
            }
            if language  == "zh-Hant" {
                return "zh-TW"
            }

            // Fall back to searching for languages starting with the current language code
            let languageCode = language.componentsSeparatedByString("-").first as String
            for l in availableLanguages {
                if l.hasPrefix(languageCode) {
                    return l
                }
            }
        }

        return currentLanguage
    }

}
