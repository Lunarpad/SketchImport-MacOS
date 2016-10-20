//
//  LPSketch.h
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sketch

// call these and make sure they return YES before executing Sketch plugin scripts
extern BOOL LPSketch_isSketchInstalled(void);
extern BOOL LPSketch_isSketchRunning(void);

extern void LPSketch_runSketchPluginScript(NSString *pluginCocoaScriptString,
                                           void(^results_block)(int terminationStatusCode,
                                                                NSString *stdoutString,
                                                                NSString *stderrString,
                                                                NSString *scriptStringOutputFromStdOut_orNil,
                                                                NSMutableDictionary *scriptJSONOutputFromStdOut_orNil));


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Plugin natively supported

// v Dump document info
void LPSketch_document(void(^results_block)(int terminationStatusCode,
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
                                            BOOL hasArtboards));

// v Dump layer info
void LPSketch_views(void(^results_block)(int terminationStatusCode,
                                         NSString *stdoutString,
                                         NSString *stderrString,
                                         NSString *scriptStringOutputFromStdOut_orNil,
                                         NSMutableDictionary *scriptJSONOutputFromStdOut_orNil));


// v Dump export
void LPSketch_views_new_exportedImageDescriptionsByLayerIds_withLayerIds(NSArray *layerIds, void(^results_block)(int terminationStatusCode,
                                                                                                                  NSString *stdoutString,
                                                                                                                  NSString *stderrString,
                                                                                                                  NSString *scriptStringOutputFromStdOut_orNil,
                                                                                                                  NSMutableDictionary *scriptJSONOutputFromStdOut_orNil));



