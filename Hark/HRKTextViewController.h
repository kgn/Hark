//
//  HRKTextViewController.h
//  Hark
//
//  Created by David Keegan on 9/24/13.
//  Copyright (c) 2013 David Keegan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HRKTextViewController : UIViewController

@property (weak, nonatomic, readonly) UITextView *textView;

- (void)promptToReplaceTextFromPasteboard;
- (void)startAutoSaveTimer;
- (void)stopAutoSaveTimer;

@end
