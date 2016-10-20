//
//  LPSketchImport.h
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern void LPSketchImport_attemptSketchImport(
    void(^__nonnull willFlattenLayersByUID_block)(NSDictionary *__nonnull layersByUID),
    BOOL(^__nonnull willImport_returningTrueIfShouldProceed_block)(NSString *__nonnull currentPageName),
    void(^__nonnull completeButDidntPerformImport_block)(NSString *_Nullable warningAlert_title_localizedString_orNilForNoAlert,
                                                         NSString *_Nullable warningAlert_message_localizedString_orNilForBlankMessage),
    void(^__nonnull receivedAnImport_block)(NSDictionary *_Nonnull importedLayersByUID)
);