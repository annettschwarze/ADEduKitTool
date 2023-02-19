//
//  LocaleUtil.h
//  ADEduKitTool
//
//  Created by Schwarze on 16.08.21.
//  Copyright © 2021 admaDIC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocaleUtil : NSObject
+ (instancetype) sharedInstance;

@property (assign, nonatomic) BOOL extensionMode;

- (NSString*) langCode;
- (NSString*) langCodeInExtension;
- (NSString*) explore;

@end

NS_ASSUME_NONNULL_END
