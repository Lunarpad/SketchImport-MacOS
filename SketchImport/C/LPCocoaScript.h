//
//  LPCocoaScript.h
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern void LPCocoaScript_runCoScript(NSString *cocoaScriptFileNamePlusExt,
                                       NSArray *argumentsToTheCocoaScript,
                                       void(^syncResults_block)(int terminationStatusCode,
                                                                NSString *stdoutString,
                                                                NSString *stderrString));

