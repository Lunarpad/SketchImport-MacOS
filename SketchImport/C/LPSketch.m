
//
//  LPSketch.m
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import "LPSketch.h"
#import "LPCocoaScript.h"
#import "LPLogging.h"
#import "NSString+Trimming.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Plugins - Shared - Loading

NSString *__LPSketch_pathToSketchPluginNamed(NSString *pluginFileName_withoutExt)
{
    return [[NSBundle mainBundle] pathForResource:pluginFileName_withoutExt ofType:@"js"];
}

NSString *_LPSketch_pathToSketchPluginScriptNamed_sketchDocument(void)
{
    return __LPSketch_pathToSketchPluginNamed(@"SketchDocument");
}

NSString *_LPSketch_pathToSketchPluginScriptNamed_sketchViews(void)
{
    return __LPSketch_pathToSketchPluginNamed(@"SketchViews");
}

NSString *_LPSketch_pathToSketchPluginScriptNamed_sketchLayerExport(void)
{
    return __LPSketch_pathToSketchPluginNamed(@"SketchLayerExport");
}

NSString *__LPSketch_pluginScriptContentsAtPath(NSString *pathToSketchPluginScript)
{
    NSError *error = NULL;
    NSString *contents = [NSString stringWithContentsOfFile:pathToSketchPluginScript encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        DDLogError(@"Couldn't read the Sketch plugin script at the path '%@'", pathToSketchPluginScript);
        return nil;
    }
    
    return contents;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Plugins - Document

void LPSketch_document(void(^syncResults_block)(int terminationStatusCode,
                                                NSString *stdoutString,
                                                NSString *stderrString,
                                                NSString *scriptStringOutputFromStdOut_orNil,
                                                NSMutableDictionary *scriptJSONOutputFromStdOut_orNil,
                                                BOOL contextExists,
                                                BOOL documentExists,
                                                BOOL isSaved,
                                                BOOL currentPageExists,
                                                NSString *currentPageName,
                                                BOOL numberOfArtboards,
                                                BOOL hasArtboards))
{
    LPSketch_runSketchPluginScript(__LPSketch_pluginScriptContentsAtPath(_LPSketch_pathToSketchPluginScriptNamed_sketchDocument()),
                                   ^(int terminationStatusCode,
                                     NSString *stdoutString, NSString *stderrString,
                                     NSString *scriptStringOutputFromStdOut_orNil,
                                     NSMutableDictionary *scriptJSONOutputFromStdOut_orNil)
    {
//        DDLogInfo(@"term %d stdout %@ stderr %@, scriptStringOutputFromStdOut_orNil '%@', scriptJSONOutputFromStdOut_orNil %@",
//                  terminationStatusCode,
//                  stdoutString, stderrString,
//                  scriptStringOutputFromStdOut_orNil,
//                  scriptJSONOutputFromStdOut_orNil);

        BOOL contextExists = NO;
        BOOL documentExists = NO;
        BOOL isSaved = NO;
        BOOL currentPageExists = NO;
        NSString *currentPageName = nil;
        NSUInteger numberOfArtboards = 0;
        BOOL hasArtboards = NO;
        {
            if ([scriptJSONOutputFromStdOut_orNil count] > 0) {
                contextExists = [scriptJSONOutputFromStdOut_orNil[@"contextExists"] boolValue];
                documentExists = [scriptJSONOutputFromStdOut_orNil[@"documentExists"] boolValue];
                isSaved = [scriptJSONOutputFromStdOut_orNil[@"isSaved"] boolValue];
                currentPageExists = [scriptJSONOutputFromStdOut_orNil[@"currentPageExists"] boolValue];
                currentPageName = scriptJSONOutputFromStdOut_orNil[@"currentPageName"];
                numberOfArtboards = [scriptJSONOutputFromStdOut_orNil[@"numberOfArtboards"] unsignedIntegerValue];
                hasArtboards = [scriptJSONOutputFromStdOut_orNil[@"hasArtboards"] boolValue];
            }
        }
        if (syncResults_block) {
            syncResults_block(terminationStatusCode,
                              stdoutString, stderrString,
                              scriptStringOutputFromStdOut_orNil,
                              scriptJSONOutputFromStdOut_orNil,
                              contextExists,
                              documentExists,
                              isSaved,
                              currentPageExists,
                              currentPageName,
                              numberOfArtboards,
                              hasArtboards);
        }
    });
}


void LPSketch_views(void(^syncResults_block)(int terminationStatusCode,
                                             NSString *stdoutString,
                                             NSString *stderrString,
                                             NSString *scriptStringOutputFromStdOut_orNil,
                                             NSMutableDictionary *scriptJSONOutputFromStdOut_orNil))
{
    LPSketch_runSketchPluginScript(__LPSketch_pluginScriptContentsAtPath(_LPSketch_pathToSketchPluginScriptNamed_sketchViews()),
                                   ^(int terminationStatusCode,
                                     NSString *stdoutString, NSString *stderrString,
                                     NSString *scriptStringOutputFromStdOut_orNil,
                                     NSMutableDictionary *scriptJSONOutputFromStdOut_orNil)
    {
//        DDLogInfo(@"term %d stdout %@ stderr %@, scriptStringOutputFromStdOut_orNil '%@', scriptJSONOutputFromStdOut_orNil %@",
//                  terminationStatusCode,
//                  stdoutString, stderrString,
//                  scriptStringOutputFromStdOut_orNil,
//                  scriptJSONOutputFromStdOut_orNil);
        
        if (syncResults_block) {
            syncResults_block(terminationStatusCode,
                              stdoutString, stderrString,
                              scriptStringOutputFromStdOut_orNil,
                              scriptJSONOutputFromStdOut_orNil);
        }
    });    
}

void LPSketch_views_new_exportedImageDescriptionsByLayerIds_withLayerIds(NSArray *layerIds, void(^results_block)(int terminationStatusCode,
                                                                                                                  NSString *stdoutString,
                                                                                                                  NSString *stderrString,
                                                                                                                  NSString *scriptStringOutputFromStdOut_orNil,
                                                                                                                  NSMutableDictionary *scriptJSONOutputFromStdOut_orNil))
{
    // here we're going to do something a little bit special - we're going to prepend some variables to the actual cocoascript we want to
    // run....
    NSMutableArray *layerIds_wrappedInEscapedDoubleQuotes = [NSMutableArray new];
    {
        for (NSString *layerId in layerIds) {
            [layerIds_wrappedInEscapedDoubleQuotes addObject:[NSString stringWithFormat:@"\"%@\"", layerId]];
        }
    }
    NSString *stringOf_layerIds_wrappedInEscapedDoubleQuotes_joinedByCommas = [layerIds_wrappedInEscapedDoubleQuotes componentsJoinedByString:@","];
    NSString *layerIds_declarationForScriptText = [NSString stringWithFormat:@"var layerIdsToExport = [ %@ ];", stringOf_layerIds_wrappedInEscapedDoubleQuotes_joinedByCommas];
    
    NSString *cocoaScriptForSketchLayerExportFile = __LPSketch_pluginScriptContentsAtPath(_LPSketch_pathToSketchPluginScriptNamed_sketchLayerExport());
    NSString *complete_cocoaScript = [NSString stringWithFormat:@"%@\n\n%@",
                                      layerIds_declarationForScriptText,
                                      cocoaScriptForSketchLayerExportFile];
        
    LPSketch_runSketchPluginScript(complete_cocoaScript,
                                   ^(int terminationStatusCode,
                                     NSString *stdoutString, NSString *stderrString,
                                     NSString *scriptStringOutputFromStdOut_orNil,
                                     NSMutableDictionary *scriptJSONOutputFromStdOut_orNil)
    {
        
        //        DDLogInfo(@"term %d stdout %@ stderr %@, scriptStringOutputFromStdOut_orNil '%@', scriptJSONOutputFromStdOut_orNil %@",
        //                  terminationStatusCode,
        //                  stdoutString, stderrString,
        //                  scriptStringOutputFromStdOut_orNil,
        //                  scriptJSONOutputFromStdOut_orNil);
        
        if (results_block) {
            results_block(terminationStatusCode,
                              stdoutString, stderrString,
                              scriptStringOutputFromStdOut_orNil,
                              scriptJSONOutputFromStdOut_orNil);
        } else {
            DDLogError(@"You should supply a results_block");
        }
    });
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sketch detection

NSString *_LPSketch_isSketch3BundleID(void)
{
    static NSString *const string = @"com.bohemiancoding.sketch3";
    
    return string;
}

BOOL LPSketch_isSketchInstalled(void)
{
    NSString *sketchAppBundlePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:_LPSketch_isSketch3BundleID()];
    NSDictionary *sketchAppBundleInfo = [[NSBundle bundleWithPath:sketchAppBundlePath] infoDictionary];
    if (!sketchAppBundleInfo) {
        return NO;
    }
    
    return YES;
}

BOOL LPSketch_isSketchRunning(void)
{
    NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:_LPSketch_isSketch3BundleID()];
    
    return runningApplications.count != 0;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cocoa script <-> Sketch plugin script

void LPSketch_runSketchPluginScript(NSString *pluginCocoaScriptString,
                                    void(^results_block)(int terminationStatusCode,
                                                         NSString *stdoutString,
                                                         NSString *stderrString,
                                                         NSString *scriptStringOutputFromStdOut_orNil,
                                                         NSMutableDictionary *scriptJSONOutputFromStdOut_orNil))
{
    static NSString *const __RunSketchPluginScript_js_fileNamePlusExt = @"RunSketchPluginScript.js";
    LPCocoaScript_runCoScript(__RunSketchPluginScript_js_fileNamePlusExt, @[ pluginCocoaScriptString ], ^(int terminationStatusCode, NSString *stdoutString, NSString *stderrString)
    {
        NSString *scriptStringOutputFromStdOut_orNil = nil;
        NSMutableDictionary *scriptJSONOutputFromStdOut_orNil = nil;
        { // First check if we ought to have some stdout
            if (terminationStatusCode == 0 && stdoutString.length > 0) {
                static NSString *const outputFollowsToken = @"Your script's output follows.";
                NSRange locationOfOutputFollowsToken = [stdoutString rangeOfString:outputFollowsToken];
                if (locationOfOutputFollowsToken.location != NSNotFound) {
                    NSUInteger locationOfStartOfOutputLine = locationOfOutputFollowsToken.location + locationOfOutputFollowsToken.length + 1; // 1 is for the newline at the end
                    scriptStringOutputFromStdOut_orNil = [stdoutString substringWithRange:NSMakeRange(locationOfStartOfOutputLine, stdoutString.length - locationOfStartOfOutputLine)];
                    { // Sanitize
                        scriptStringOutputFromStdOut_orNil = [scriptStringOutputFromStdOut_orNil stringByTrimmingWrappingWhitespace];
                    }
                    if (scriptStringOutputFromStdOut_orNil.length > 0) {
                        { // now we'll attempt to parse, but if it fails, we'll only log error, we won't make the control flow think there's an error
                            NSError *error = NULL;
                            NSData *dataFromString = [scriptStringOutputFromStdOut_orNil dataUsingEncoding:NSUTF8StringEncoding];
                            NSMutableDictionary *parsedDictionary = [NSJSONSerialization JSONObjectWithData:dataFromString options:NSJSONReadingMutableContainers error:&error];
                            if (error != NULL) {
                                DDLogWarn(@"This is probably fine, but there was an error parsing as string received from Sketch as JSON.\n\nError: %@.\n\nString: '%@'. This could be fine if it's not meant to be JSON output.", error, scriptStringOutputFromStdOut_orNil);
                            } else {
                                scriptJSONOutputFromStdOut_orNil = parsedDictionary;
                            }
                        }
                    }
                }
            }
        }
        { // Now yield
            if (results_block) {
                results_block(terminationStatusCode,
                              stdoutString, stderrString,
                              scriptStringOutputFromStdOut_orNil,
                              scriptJSONOutputFromStdOut_orNil);
            } else {
                DDLogError(@"You should supply a results_block");
            }
        }
    });
}