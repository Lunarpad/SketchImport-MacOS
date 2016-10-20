//
//  LPLogging.h
//  SketchImport
//
//  Created by Paul Shapiro on 7/19/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#ifndef LPLogging_h
#define LPLogging_h

    #if defined(DEBUG) || defined(INTERNAL) || (ENABLE_LOGS==1)
        #define DDLogInfo(...) NSLog(@"💬 %@", [NSString stringWithFormat:__VA_ARGS__])
        #define DDLogError(...) NSLog(@"❌ Error: %@", [NSString stringWithFormat:__VA_ARGS__])
        #define DDLogWarn(...) NSLog(@"⚠️ Warn: %@", [NSString stringWithFormat:__VA_ARGS__])
    #else
        #define DDLogInfo(...) ((void)0)
        #define DDLogError(...) ((void)0)
        #define DDLogWarn(...) ((void)0)
    #endif

#endif
