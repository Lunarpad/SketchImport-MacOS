//
//  NSString+Trimming.h
//  SketchImport
//
//  Created by Paul Shapiro on 5/12/15.
//  Copyright (c) 2015 Lunarpad Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Trimming)

- (NSString *)stringByTrimmingLeadingWhitespace;
- (NSString *)stringByTrimmingTrailingWhitespace;

- (NSString *)stringByTrimmingWrappingWhitespace; // just calls stringByTrimming(Leading, Trailing)Whitespace

@end
