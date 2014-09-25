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

    var isSpeaking: Bool {
        return self.speechSynthesizer.speaking
    }

    func readText(text: String, voiceLanguage: String?, rate: Float = 1, volume: Float = 1, pitchMultiplier: Float = 1) {
        if self.isSpeaking {
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitchMultiplier
        if let language = voiceLanguage {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }

        self.speechSynthesizer.speakUtterance(utterance)
    }

//    func voiceLanguage(text: String) -> String {
//    CFRange range = CFRangeMake(0, MIN(400, text.length));
//    NSString *currentLanguage = [AVSpeechSynthesisVoice currentLanguageCode];
//    NSString *language = (NSString *)CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage((CFStringRef)text, range));
//    if(language && ![currentLanguage hasPrefix:language]){
//    NSArray *availableLanguages = [[AVSpeechSynthesisVoice speechVoices] valueForKeyPath:@"language"];
//    if([availableLanguages containsObject:language]){
//    return language;
//    }
//
//    // TODO: also support Cantonese (zh-HK)
//    // Language code translations for simplified and traditional Chinese
//    if([language isEqualToString:@"zh-Hans"]){
//    return @"zh-CN";
//    }
//    if([language isEqualToString:@"zh-Hant"]){
//    return @"zh-TW";
//    }
//
//    // Fall back to searching for languages starting with the current language code
//    NSString *languageCode = [[language componentsSeparatedByString:@"-"] firstObject];
//    for(NSString *language in availableLanguages){
//    if([language hasPrefix:languageCode]){
//    return language;
//    }
//    }
//    }
//
//    return currentLanguage;
//    }

}
