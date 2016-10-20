//
//  LPCocoaScript.m
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import "LPCocoaScript.h"
#import "LPLogging.h"

extern void LPCocoaScript_runCoScript(NSString *cocoaScriptFileNamePlusExt,
                                       NSArray *argumentsToTheCocoaScript,
                                       void(^results_block)(int terminationStatusCode, NSString *stdoutString, NSString *stderrString))
{
    NSString *applicationBundleResourcesPath = [[NSBundle mainBundle] resourcePath];
    NSString *absolutePathToBinary = [applicationBundleResourcesPath stringByAppendingPathComponent:@"coscript"];
    NSString *absolutePathToCocoaScriptFile = [applicationBundleResourcesPath stringByAppendingPathComponent:cocoaScriptFileNamePlusExt];
    NSMutableArray *args = [NSMutableArray new];
    {
        [args addObject:absolutePathToCocoaScriptFile];
        if ([argumentsToTheCocoaScript count] > 0) {
            [args addObjectsFromArray:argumentsToTheCocoaScript];
        }
    }
    __block BOOL hasShownErrorForThisTaskAlready = NO;

    
    NSPipe *stdOutPipe = [NSPipe pipe];
    NSPipe *stdErrPipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    {
        task.launchPath = absolutePathToBinary;
        task.arguments = args;
        task.standardOutput = stdOutPipe;
        task.standardError = stdErrPipe;
    }
    
//    DDLogInfo(@"%@ %@", absolutePathToBinary, [args componentsJoinedByString:@" "]);
    
    NSFileHandle *stdOutFileHandleForReading = [stdOutPipe fileHandleForReading];
    NSFileHandle *stdErrFileHandleForReading = [stdErrPipe fileHandleForReading];
    NSMutableData *standardOutData = [NSMutableData new];
    NSMutableData *standardErrorData = [NSMutableData new];
    
    task.terminationHandler = ^(NSTask *task)
    { // "When your task terminates, you have to set readabilityHandler block to nil; otherwise, you'll encounter high CPU usage, as the reading will never stop."
        DDLogInfo(@"LPCocoaScript task terminated with code %d and reason '%@'.", task.terminationStatus, task.terminationReason == 1 ? @"exit" : @"uncaught signal");
        
        NSString *standardOutString = [[NSString alloc] initWithData:standardOutData encoding:NSUTF8StringEncoding];
        NSString *standardErrorString = [[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding];

        switch (task.terminationStatus) {
            case 0:
            { // success, or known error
                break;
            }
                
            default:
            {
                
//                if (task.terminationStatus == 11) {
//                    if (standardErrorString.length == 0) { // which means we've not handled the error in the stderr handler
//                        hasShownErrorForThisTaskAlready = YES;
//                        
//                        // relay that error is whatever status 11 means…
//                    }
//                }
                
                break;
            }
        }
        
        // teardown io observation
        [task.standardOutput fileHandleForReading].readabilityHandler = nil;
        [task.standardError fileHandleForReading].readabilityHandler = nil;
        
        // now we can yield!
        results_block(task.terminationStatus, standardOutString, standardErrorString);
        
    };
    
    [stdOutFileHandleForReading setReadabilityHandler:^(NSFileHandle *fileHandle)
    {
        NSData *newData = [fileHandle availableData];
        [standardOutData appendData:newData];
         // ^ accumulate
         
//        NSString *newString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
//        NSString *standardOutString = [[NSString alloc] initWithData:standardOutData encoding:NSUTF8StringEncoding];
//        DDLogInfo(@"[INFO]: LPCocoaScript says '%@'", newString);
//        if ([standardOutString containsString:@"Device Locked"]) {
//         // this is an 'error' that could be seen via stdout
//         
//         return;
//        }
    }];
    
    [stdErrFileHandleForReading setReadabilityHandler:^(NSFileHandle *fileHandle)
     {
         NSData *newData = [fileHandle availableData];
         NSString *newString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
         [standardErrorData appendData:newData];
         NSString *standardErrorString = [[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding];
         DDLogInfo(@"LPCocoaScript [ERROR]: '%@'", newString);
         
         if (hasShownErrorForThisTaskAlready) {
             DDLogWarn(@"Already shown error for this LPCocoaScript task.");
             
             return;
         }
         
         if (standardErrorString.length != 0) {
             BOOL hasShownAlert = NO;
//             if ([standardErrorString containsString:@"Timed out waiting for device."]) {
//                 // some specific alert
//                 hasShownAlert = YES;
//             }
             if (hasShownAlert == NO) {
                 // do an 'unknown' alert
             }
             
             return;
         }
     }];
    {
        [task launch];
    }
}
