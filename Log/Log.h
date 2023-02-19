//
//  Log.h
//  ADEduKitTool
//
//  Created by Annett Schwarze on 12.02.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 A primitive log macro, which uses ``NSLog`` and only logs when ``DEBUG``is defined.
 Don't import it in Swift - only use it in Objective C code.
 */

#if DEBUG
#define ADLog(fmt, ...) NSLog(fmt, ## __VA_ARGS__)
#else
#define ADLog(fmt, ...)
#endif

NS_ASSUME_NONNULL_END
