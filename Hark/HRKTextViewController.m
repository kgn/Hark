//
//  HRKTextViewController.m
//  Hark
//
//  Created by David Keegan on 9/24/13.
//  Copyright (c) 2013 David Keegan. All rights reserved.
//

@import AVFoundation;

#import "HRKTextViewController.h"
#import "UIAlertView+BBlock.h"
#import "NSTimer+BBlock.h"
#import "BBlock.h"
#import "KGKeyboardChangeManager.h"

@interface HRKTextViewController()
<UITextViewDelegate, AVSpeechSynthesizerDelegate>
@property (weak, nonatomic, readwrite) UITextView *textView;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) id keyboardChangeIdentifier;
@property (nonatomic, getter=isSpeaking) BOOL speaking;
@end

@implementation HRKTextViewController

- (void)dealloc{
    [self stopAutoSaveTimer];
    [[KGKeyboardChangeManager sharedManager] removeObserverWithIdentifier:self.keyboardChangeIdentifier];
}

- (void)viewDidLoad{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Hark", @"Hark Title");
    self.view.backgroundColor = [UIColor whiteColor];

    self.speechSynthesizer = [AVSpeechSynthesizer new];
    self.speechSynthesizer.delegate = self;

    NSError *error = nil;
    if(![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error]){
        NSLog(@"%@", error);
    }

    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self action:@selector(actionButtonAction:)];
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                  target:self action:@selector(readButtonAction:)];

    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.delegate = self;
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textView.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"app.lastText"];
    [self.view addSubview:textView];
    self.textView = textView;

    if([self.textView.text length] == 0){
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }

    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Read", @"Menu item read title") action:@selector(readMenuAction:)];
    [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:menuItem]];

    BBlockWeakSelf wself = self;
    self.keyboardChangeIdentifier = [[KGKeyboardChangeManager sharedManager] addObserverForKeyboardChangedWithBlock:^(BOOL show, CGRect keyboardRect, NSTimeInterval animationDuration, UIViewAnimationCurve animationCurve){
        [KGKeyboardChangeManager animateWithWithDuration:animationDuration animationCurve:animationCurve andAnimation:^{
            CGRect frame = wself.view.bounds;
            frame.size.height = CGRectGetMinY(keyboardRect);
            wself.textView.frame = frame;
        }];
    }];

    [self.textView becomeFirstResponder];
}

- (void)setSpeaking:(BOOL)speaking{
    _speaking = speaking;

    if(self.isSpeaking){
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self action:@selector(stopButtonAction:)];
    }else{
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                      target:self action:@selector(readButtonAction:)];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if(action == @selector(readMenuAction:)){
        if(self.textView.selectedRange.length > 0){
            return YES;
        }
    }
    return NO;
}

- (void)startAutoSaveTimer{
    BBlockWeakSelf wself = self;
    [self stopAutoSaveTimer];
    self.timer = [NSTimer scheduledTimerRepeats:YES withTimeInterval:20 andBlock:^{
        [[NSUserDefaults standardUserDefaults] setObject:wself.textView.text forKey:@"app.lastText"];
    }];
}

- (void)stopAutoSaveTimer{
    [self.timer invalidate];
}

- (void)promptToReplaceTextFromPasteboard{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if([pasteboard.string length] == 0){
        return;
    }

    if([self.textView.text isEqualToString:pasteboard.string] ||
       [pasteboard.string isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"app.askedText"]]){
        return;
    }

    BBlockWeakSelf wself = self;
    [[[UIAlertView alloc]
     initWithTitle:NSLocalizedString(@"Replace from Clipboard?", @"Replace with clipboard title")
     message:NSLocalizedString(@"There is new text in your clipboard, would you like to use it?", @"Replace with clipboard message")
     cancelButtonTitle:NSLocalizedString(@"NO", @"NO button") otherButtonTitle:NSLocalizedString(@"Use Text", @"Use text button")
     completionBlock:^(NSInteger buttonIndex, UIAlertView *alertView){
         if(buttonIndex == alertView.cancelButtonIndex){
             [[NSUserDefaults standardUserDefaults] setObject:pasteboard.string forKey:@"app.askedText"];
         }else{
             wself.textView.text = pasteboard.string;
             [wself.navigationItem.leftBarButtonItem setEnabled:YES];
             [wself.navigationItem.rightBarButtonItem setEnabled:YES];
         }
     }] show];
}

- (void)readText{
    if(self.speechSynthesizer.isSpeaking){
        return;
    }

    NSString *text = self.textView.text;
    if(self.textView.selectedRange.length > 0){
        text = [text substringWithRange:self.textView.selectedRange];
    }
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:[self voiceLanguageForText:text]];
    [self.speechSynthesizer speakUtterance:utterance];
}

// Determine best language language for the string from up to the first 400 characters
- (NSString *)bestLanguageForString:(NSString *)text {
    return (NSString *)CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage((CFStringRef)text, CFRangeMake(0, MIN(400, text.length))));
}

- (NSString *)voiceLanguageForText:(NSString *)text {
    NSString *language = [self bestLanguageForString:text];
    
    // Default to the current system language
    NSString *currentLanguage = [AVSpeechSynthesisVoice currentLanguageCode];
    if (language && ![currentLanguage hasPrefix:language]) {
        NSArray *availableLanguages = [[AVSpeechSynthesisVoice speechVoices] valueForKeyPath:@"language"];
        
        // See if the detected language is in the available speech voices
        if ([availableLanguages containsObject:language]) {
            return language;
        }
        
        // Language code translations for simplified and traditional Chinese
        if ([language isEqual:@"zh-Hans"]){
            return @"zh-CN";
        }
        
        // TODO: also support Cantonese (zh-HK)
        if ([language isEqual:@"zh-Hant"]){
            return @"zh-TW";
        }
        
        // Fall back to searching the availableLanguages array for languages starting with
        // the current language code
        NSString *langCode = [[language componentsSeparatedByString:@"-"] firstObject];
        for (NSString *lang in availableLanguages) {
            if ([lang hasPrefix:langCode]) {
                return lang;
            }
        }
    }
    
    return currentLanguage;
}

- (void)actionButtonAction:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"app.lastText"];

    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)readButtonAction:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"app.lastText"];
    [self readText];
}

- (void)readMenuAction:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"app.lastText"];
    [self readText];
}

- (void)stopButtonAction:(id)sender{
    if(self.speechSynthesizer.isSpeaking){
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

- (void)textViewDidChange:(UITextView *)textView{
    if([textView.text length]){
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }else{
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = YES;
}

@end
