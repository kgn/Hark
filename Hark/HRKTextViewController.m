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
#import "InAppSettings.h"

@interface HRKTextViewController()
<UITextViewDelegate, AVSpeechSynthesizerDelegate>
@property (weak, nonatomic, readwrite) UITextView *textView;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) id keyboardChangeIdentifier;
@property (nonatomic, getter=isSpeaking) BOOL speaking;
@property (nonatomic) NSUInteger startLocation;
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

    UIBarButtonItem *settingsBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain
                                                  target:self action:@selector(settingsButtonAction:)];
    UIBarButtonItem *actionBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self action:@selector(actionButtonAction:)];
    self.navigationItem.leftBarButtonItems = @[settingsBarButtonItem, actionBarButtonItem];

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
     cancelButtonTitle:NSLocalizedString(@"No", @"No button") otherButtonTitle:NSLocalizedString(@"Use Text", @"Use text button")
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
    
    self.startLocation = 0;
    NSString *text = self.textView.text;
    if(self.textView.selectedRange.length > 0){
        self.startLocation = self.textView.selectedRange.location;
        text = [text substringWithRange:self.textView.selectedRange];
    }

    NSString *voiceLanguage = [self voiceLanguageForText:text];
    // Build this our self cuase NSLocaleIdentifier uses "_"
    NSString *currentVoiceLanguage = [NSString stringWithFormat:@"%@-%@",
                                      [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode],
                                      [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
    if([voiceLanguage isEqualToString:currentVoiceLanguage]){
        [self readText:text withVoiceLanguage:nil];
    }else{
        BBlockWeakSelf wself = self;

        NSString *displayLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:voiceLanguage];
        NSString *currentDisplayLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:currentVoiceLanguage];

        UIAlertView *alertView =
        [[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"Foreign Language Detected", @"Foreign language alert title")
         message:NSLocalizedString(@"We think the text might be in another language, which language would you like the text read in?", @"Foreign language alert message")
         delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button")
         otherButtonTitles:displayLanguage, currentDisplayLanguage, nil];

        [alertView setCompletionBlock:^(NSInteger buttonIndex, UIAlertView *alertView) {
            if(buttonIndex == alertView.cancelButtonIndex){
                return;
            }

            if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:displayLanguage]){
                [wself readText:text withVoiceLanguage:voiceLanguage];
            }else{
                [wself readText:text withVoiceLanguage:nil];
            }
        }];

        [alertView show];
    }
}

- (void)readText:(NSString *)text withVoiceLanguage:(NSString *)voiceLanguage{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    if([voiceLanguage length]){
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:voiceLanguage];
    }
    utterance.rate = [[NSUserDefaults standardUserDefaults] floatForKey:@"utterance.rate"];
    utterance.volume = [[NSUserDefaults standardUserDefaults] floatForKey:@"utterance.volume"];
    utterance.pitchMultiplier = [[NSUserDefaults standardUserDefaults] floatForKey:@"utterance.pitchMultiplier"];
    [self.speechSynthesizer speakUtterance:utterance];
}

- (NSString *)voiceLanguageForText:(NSString *)text{
    CFRange range = CFRangeMake(0, MIN(400, text.length));
    NSString *currentLanguage = [AVSpeechSynthesisVoice currentLanguageCode];
    NSString *language = (NSString *)CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage((CFStringRef)text, range));
    if(language && ![currentLanguage hasPrefix:language]){
        NSArray *availableLanguages = [[AVSpeechSynthesisVoice speechVoices] valueForKeyPath:@"language"];
        if([availableLanguages containsObject:language]){
            return language;
        }

        // TODO: also support Cantonese (zh-HK)
        // Language code translations for simplified and traditional Chinese
        if([language isEqualToString:@"zh-Hans"]){
            return @"zh-CN";
        }
        if([language isEqualToString:@"zh-Hant"]){
            return @"zh-TW";
        }

        // Fall back to searching for languages starting with the current language code
        NSString *languageCode = [[language componentsSeparatedByString:@"-"] firstObject];
        for(NSString *language in availableLanguages){
            if([language hasPrefix:languageCode]){
                return language;
            }
        }
    }

    return currentLanguage;
}

- (void)settingsButtonAction:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"app.lastText"];

    InAppSettingsModalViewController *settingViewController = [InAppSettingsModalViewController new];
    settingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:settingViewController animated:YES completion:nil];
    [self.textView resignFirstResponder];
}

- (void)actionButtonAction:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"app.lastText"];

    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[self.textView.text] applicationActivities:nil];
    // TODO: handle iPhone/iPad
    [self presentViewController:activityViewController animated:YES completion:nil];
    [self.textView resignFirstResponder];
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
    [self removeAttributes];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = NO;
    [self removeAttributes];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.speaking = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    NSRange textRange = NSMakeRange(0, self.textView.text.length);
    NSRange readRange = NSMakeRange(self.startLocation, characterRange.location+characterRange.length);
    NSMutableAttributedString *spokenText = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
    [spokenText addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:textRange];
    [spokenText addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:textRange];
    [spokenText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:readRange];
    [spokenText addAttribute:NSBackgroundColorAttributeName value:self.view.tintColor range:readRange];
    self.textView.attributedText = spokenText;
}

- (void)removeAttributes{
    NSRange textRange = NSMakeRange(0, self.textView.text.length);
    NSMutableAttributedString *textToReset = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
    [textToReset addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:textRange];
    [textToReset addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:textRange];
    [textToReset addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:textRange];
    self.textView.attributedText = textToReset;
}

@end
