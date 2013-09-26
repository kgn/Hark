//
//  HRKAppDelegate.m
//  Hark
//
//  Created by David Keegan on 9/24/13.
//  Copyright (c) 2013 David Keegan. All rights reserved.
//

#import "HRKAppDelegate.h"
#import "HRKTextViewController.h"
#import "UIColor+Hex.h"

@interface HRKAppDelegate()
@property (weak, nonatomic) HRKTextViewController *textViewController;
@end

@implementation HRKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setTintColor:[UIColor colorWithHex:0xff3b30]];

    HRKTextViewController *viewController = [HRKTextViewController new];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.textViewController = viewController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application{
    [self.textViewController stopAutoSaveTimer];
    [[NSUserDefaults standardUserDefaults] setObject:self.textViewController.textView.text forKey:@"app.lastText"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    [self.textViewController promptToReplaceTextFromPasteboard];
    [self.textViewController startAutoSaveTimer];
}

- (void)applicationWillTerminate:(UIApplication *)application{
    [[NSUserDefaults standardUserDefaults] setObject:self.textViewController.textView.text forKey:@"app.lastText"];
}

@end
