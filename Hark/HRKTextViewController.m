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
#import "UIColor+Hex.h"

@interface HRKTextViewController()
<UITextViewDelegate, AVSpeechSynthesizerDelegate>
@property (weak, nonatomic, readwrite) UITextView *textView;
@property (weak, nonatomic, readwrite) UILabel *rateNumber;
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
    [self.view setTintColor:[UIColor colorWithHex:0xff3b30]];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"app.utterance.rate"]) {
        [[NSUserDefaults standardUserDefaults] setFloat:0.25 forKey:@"app.utterance.rate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
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
            //wself.textView.contentInset = UIEdgeInsetsMake(64, 0, keyboardRect.size.height, 0);
            //wself.textView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, keyboardRect.size.height, 0);
        }];
    }];

    UIToolbar *accessoryBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [accessoryBar setTintColor:self.view.tintColor];
    [accessoryBar setBarStyle:UIBarStyleDefault];
    [accessoryBar setTranslucent:YES];
    
    UISlider *rateSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 230, 23)];
    [rateSlider setMinimumValue:AVSpeechUtteranceMinimumSpeechRate];
    [rateSlider setMaximumValue:AVSpeechUtteranceMaximumSpeechRate];
    [rateSlider setValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"app.utterance.rate"] animated:YES];
    [rateSlider addTarget:self action:@selector(rateAdjusted:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *rateItem = [[UIBarButtonItem alloc] initWithCustomView:rateSlider];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UILabel *percentage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 23)];
    [percentage setTextAlignment:NSTextAlignmentRight];
    [percentage setText:[NSString stringWithFormat:@"%.0f%%", [[NSUserDefaults standardUserDefaults] floatForKey:@"app.utterance.rate"] * 100 ]];
    self.rateNumber = percentage;
    UIBarButtonItem *ratePercent = [[UIBarButtonItem alloc] initWithCustomView:self.rateNumber];
    
    [accessoryBar setItems:@[rateItem, flexibleSpace, ratePercent]];
    
    [self.textView setInputAccessoryView:accessoryBar];
    [self.textView becomeFirstResponder];
}

- (void)rateAdjusted:(UISlider *)slider {
    NSLog(@"%f", slider.value);
    
    self.rateNumber.text = [NSString stringWithFormat:@"%.0f%%", slider.value * 100];
    
    [[NSUserDefaults standardUserDefaults] setFloat:slider.value forKey:@"app.utterance.rate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:[self voiceLanguageForText:text]];
    utterance.rate = [[NSUserDefaults standardUserDefaults] floatForKey:@"app.utterance.rate"];
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
                NSLog(@"Falling back on: %@", language);
                return language;
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
