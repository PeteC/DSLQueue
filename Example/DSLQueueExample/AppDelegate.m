//
//  AppDelegate.m
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright (c) 2011 Dative Studios. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"


@implementation AppDelegate

@synthesize window=__window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ViewController *viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
