//
//  LocaleUtil.m
//  ADEduKitTool
//
//  Created by Schwarze on 16.08.21.
//  Copyright © 2021 admaDIC. All rights reserved.
//

#import "LocaleUtil.h"
#import "Log.h"

@implementation LocaleUtil

+ (instancetype) sharedInstance {
    static LocaleUtil* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LocaleUtil alloc] init];
    });
    return instance;
}

- (NSString*) langCode {
    if (self.extensionMode)
        return self.langCodeInExtension;

    NSString *rc = @"en"; // Lets use "en" as default
    NSBundle *b = [NSBundle mainBundle];
    NSArray<NSString*> *ls = b.preferredLocalizations;
    // ADLog(@"%s: ls=%@", __PRETTY_FUNCTION__, ls);
    if (ls.count > 0) {
        rc = ls.firstObject;
        // Make sure, only a two-letter code is returned
        rc = [rc substringToIndex:2];
    }
    return rc;
}

- (NSString*) langCodeInExtension {
    NSString *rc = @"en"; // Lets use "en" as default
    // Bundle is always "en" when opened as extension
    // NSBundle *b = [NSBundle mainBundle];
    // Use NSLocale for that
    NSArray<NSString*> *ls = NSLocale.preferredLanguages;
    // ADLog(@"%s: ls=%@", __PRETTY_FUNCTION__, ls);
    if (ls.count > 0) {
        rc = ls.firstObject;
        // Make sure, only a two-letter code is returned
        rc = [rc substringToIndex:2];
    }
    return rc;
}

/**
 Helper method to easily dump the locales.
 */
-(NSString *)explore {
    NSBundle *b = [NSBundle mainBundle];
    ADLog(@"%s: mainBundle = %@", __PRETTY_FUNCTION__, b);
    NSArray<NSString*> *ls = b.preferredLocalizations;
    ADLog(@"%s: mainBundle.preferredLocalizations = %@", __PRETTY_FUNCTION__, ls);

    NSArray<NSString*> *ls2 = NSLocale.preferredLanguages;
    ADLog(@"%s: NSLocale.preferredLocalizations = %@", __PRETTY_FUNCTION__, ls2);

    return nil;
}

@end
