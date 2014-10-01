//
//  TextViewController.swift
//  Hark
//
//  Created by David Keegan on 9/24/14.
//  Copyright (c) 2014 David Keegan. All rights reserved.
//

import UIKit
import AVFoundation

// TODO: *Implement keyboard logic to move the text view out of the way
// TODO: Implement auto save?
// TODO: Implement settings

class TextViewController: UIViewController, UITextViewDelegate, AVSpeechSynthesizerDelegate {

    private var textViewBottomConstraint: NSLayoutConstraint?
    lazy internal var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        self.view.addSubview(textView)
        textView.pinToSideEdgesOfSuperview()
        textView.pinToTopEdgeOfSuperview()
        self.textViewBottomConstraint = textView.pinToBottomEdgeOfSuperview()
        return textView
    }()

    private var startLocation: Int = 0

    lazy private var speechEngine: SpeechEngine = {
        let speechEngine = SpeechEngine()
        return speechEngine
    }()

    var speaking: Bool = false {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: self.isSpeaking ? .Stop : .Play,
                target: self, action: self.isSpeaking ? "stopButtonAction" : "readButtonAction")
        }
    }
    var isSpeaking: Bool { return self.speaking }

    internal func startAutoSaveTimer() {

    }

    internal func stopAutoSaveTimer() {

    }

    internal func promptToReplaceTextFromPasteboard() {
        let pasteboard = UIPasteboard.generalPasteboard()
        if pasteboard.string == nil || countElements(pasteboard.string!) == 0 {
            return
        }

        if self.textView.text == pasteboard.string! {
            return
        }

        let askedText = NSUserDefaults.standardUserDefaults().objectForKey("app.askedText") as String?
        if askedText != nil && pasteboard.string! == askedText! {
            return
        }

        let alertController = UIAlertController(
            title: NSLocalizedString("Replace from Clipboard?", comment: "Replace with clipboard title"),
            message: NSLocalizedString("There is new text in your clipboard, would you like to use it?", comment: "Replace with clipboard message"),
            preferredStyle: .Alert
        )
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Use Text", comment: "Use text button"), style: UIAlertActionStyle.Default) { _ in
            self.setText(pasteboard.string)
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "No button"), style: UIAlertActionStyle.Cancel) { _ in
            NSUserDefaults.standardUserDefaults().setObject(pasteboard.string, forKey:"app.askedText")
        })
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup Navigation Bar UI
        self.title = NSLocalizedString("Hark", comment: "Hark Title")
        let settingsBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .Plain, target: self, action: "settingsButtonAction")
        let actionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "actionButtonAction")
        self.navigationItem.leftBarButtonItems = [settingsBarButtonItem, actionBarButtonItem]
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "readButtonAction")

        self.setText(NSUserDefaults.standardUserDefaults().stringForKey("app.lastText"))

        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: nil) { notification in
            if let textViewBottomConstraint = self.textViewBottomConstraint {
                if let userInfo = notification.userInfo {
                    let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
                    let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber
                    // TODO: figure out this conversion
//                    let curve: UIViewAnimationOptions! = UIViewAnimationOptions.fromRaw(UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as NSNumber).unsignedIntValue << 16))
                    textViewBottomConstraint.constant = -keyboardFrame.size.height
                    UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillHideNotification, object: nil, queue: nil) { notification in
            if let textViewBottomConstraint = self.textViewBottomConstraint {
                if let userInfo = notification.userInfo {
                    let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber
                    textViewBottomConstraint.constant = 0
                    UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }

        let menuItem = UIMenuItem(title: NSLocalizedString("Read", comment: "Menu item read title"), action: "readMenuAction")
        UIMenuController.sharedMenuController().menuItems = [menuItem]

        self.speechEngine.speechSynthesizer.delegate = self

        var audioError: NSError?
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: &audioError)
        if let error = audioError {
            println("audio error: \(error.localizedDescription)")
        }
    }

    override func viewDidAppear(animated: Bool) {
        self.textView.becomeFirstResponder()
    }

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == "readMenuAction" && self.textView.selectedRange.length > 0{
            return true
        }
        return false
    }

    private func setText(text: String?) {
        self.textView.text = text
        self.updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        if countElements(self.textView.text) == 0 {
            self.navigationItem.leftBarButtonItem?.enabled = false
            self.navigationItem.rightBarButtonItem?.enabled = false
        } else {
            self.navigationItem.leftBarButtonItem?.enabled = true
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
    }

    private func readText() {
        if self.isSpeaking {
            return
        }

        self.startLocation = 0
        var text = self.textView.text
        if self.textView.selectedRange.length > 0 {
            self.startLocation = self.textView.selectedRange.location
            text = (text as NSString).substringWithRange(self.textView.selectedRange)
        }

        // TODO: load defaults
        let rate: Float = 0.5//NSUserDefaults.standardUserDefaults().floatForKey("utterance.rate")
        let volume: Float = 1//NSUserDefaults.standardUserDefaults().floatForKey("utterance.volume")
        let pitchMultiplier: Float = 1//NSUserDefaults.standardUserDefaults().floatForKey("utterance.pitchMultiplier")

        let textVoiceLanguage = self.speechEngine.voiceLanguage(text)
        let systemVoiceLanguage = self.speechEngine.systemVoiceLanguage()
        if textVoiceLanguage == systemVoiceLanguage {
            self.speechEngine.readText(text, rate: rate, volume: volume, pitchMultiplier: pitchMultiplier)
            return
        }

        var displayLanguage: String! = NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: textVoiceLanguage)
        var systemDisplayLanguage: String! = NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: systemVoiceLanguage)

        if displayLanguage == nil {
            displayLanguage = textVoiceLanguage
        }

        if systemDisplayLanguage == nil {
            systemDisplayLanguage = systemVoiceLanguage
        }

        let alertController = UIAlertController(
            title: NSLocalizedString("Foreign Language Detected", comment: "Foreign language alert title"),
            message: NSLocalizedString("The text appears to be in a different language than the system settings, which language would you like the text read in?", comment: "Foreign language alert message"),
            preferredStyle: .Alert
        )
        alertController.addAction(UIAlertAction(title: displayLanguage, style: UIAlertActionStyle.Default) { _ in
            self.speechEngine.readText(text, rate: rate, volume: volume, pitchMultiplier: pitchMultiplier)
        })
        alertController.addAction(UIAlertAction(title: systemDisplayLanguage, style: UIAlertActionStyle.Default) { _ in
            self.speechEngine.readText(text, voiceLanguage: systemVoiceLanguage, rate: rate, volume: volume, pitchMultiplier: pitchMultiplier)
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    private func saveText() {
        NSUserDefaults.standardUserDefaults().setObject(self.textView.text, forKey:"app.lastText")
    }

    private func removeAttributes() {
        self.textView.attributedText = NSAttributedString(string: self.textView.text, attributes: [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSBackgroundColorAttributeName: UIColor.clearColor(),
            NSForegroundColorAttributeName: UIColor.blackColor()
        ])
    }

    // MARK: - Actions

    @objc private func settingsButtonAction() {
        self.saveText()
    }

    @objc private func actionButtonAction() {
        self.saveText()

        let activityViewController = UIActivityViewController(activityItems: [self.textView.text], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
        self.textView.resignFirstResponder()
    }

    @objc private func readButtonAction() {
        self.saveText()
        self.readText()
    }

    @objc private func readMenuAction() {
        self.saveText()
        self.readText()
    }

    @objc private func stopButtonAction() {
        self.speechEngine.stopReading()
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(textView: UITextView) {
        self.updateNavigationButtons()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didStartSpeechUtterance utterance: AVSpeechUtterance!) {
        self.speaking = true
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        self.speaking = false
        self.removeAttributes()
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didPauseSpeechUtterance utterance: AVSpeechUtterance!) {
        self.speaking = false
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didContinueSpeechUtterance utterance: AVSpeechUtterance!) {
        self.speaking = true
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didCancelSpeechUtterance utterance: AVSpeechUtterance!) {
        self.speaking = false
        self.removeAttributes()
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance!) {
        let textRange = NSMakeRange(0, countElements(self.textView.text))
        let readRange = NSMakeRange(self.startLocation, characterRange.location+characterRange.length)
        let spokenText = NSMutableAttributedString(string: self.textView.text)
        spokenText.addAttribute(NSFontAttributeName, value: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), range: textRange)
        spokenText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.clearColor(), range: textRange)
        spokenText.addAttribute(NSForegroundColorAttributeName, value:UIColor.whiteColor(), range: readRange)
        spokenText.addAttribute(NSBackgroundColorAttributeName, value:self.view.tintColor, range: readRange)
        self.textView.attributedText = spokenText;
    }
}
