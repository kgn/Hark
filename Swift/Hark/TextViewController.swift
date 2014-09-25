//
//  TextViewController.swift
//  Hark
//
//  Created by David Keegan on 9/24/14.
//  Copyright (c) 2014 David Keegan. All rights reserved.
//

import UIKit
import AVFoundation

class TextViewController: UIViewController, UITextViewDelegate {

    lazy internal var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        return textView
    }()

    lazy private var speechEngine: SpeechEngine = {
        let speechEngine = SpeechEngine()
        return speechEngine
    }()

//    var speaking: Bool = false {
//        didSet {
//            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: self.speaking ? .Stop : .Play, target: self, action: "readButtonAction")
//        }
//    }

    internal func promptToReplaceTextFromPasteboard() {

    }

    internal func startAutoSaveTimer() {

    }

    internal func stopAutoSaveTimer() {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup Navigation Bar UI
        self.title = NSLocalizedString("Hark", comment: "Hark Title")
        let settingsBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .Plain, target: self, action: "settingsButtonAction")
        let actionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "actionButtonAction")
        self.navigationItem.leftBarButtonItems = [settingsBarButtonItem, actionBarButtonItem]
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "readButtonAction")

        self.view.addSubview(self.textView)
        self.textView.becomeFirstResponder()
        self.textView.pinToEdgesOfSuperview()
        self.textView.text = NSUserDefaults.standardUserDefaults().stringForKey("app.lastText")
        self.updateNavigationButtons()

        let menuItem = UIMenuItem(title: NSLocalizedString("Read", comment: "Menu item read title"), action: "readMenuAction")
        UIMenuController.sharedMenuController().menuItems = [menuItem]

        var audioError: NSError?
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: &audioError)
        if let error = audioError {
            println("audio error: \(error.localizedDescription)")
        }

    }

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == "readMenuAction" && self.textView.selectedRange.length > 0{
            return true
        }
        return false
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

    // MARK: - UITextViewDelegate

    func textViewDidChange(textView: UITextView) {
        self.updateNavigationButtons()
    }

    // MARK: - Actions

    @objc private func settingsButtonAction() {

    }

    @objc private func actionButtonAction() {

    }

    @objc private func readButtonAction() {

    }

    @objc private func readMenuAction() {

    }
}
