//
//  LPSketchImport.m
//  SketchImport
//
//  Created by Paul Shapiro on 11/26/15.
//  Copyright © 2015 Lunarpad Corporation. All rights reserved.
//

#import "LPSketchImport.h"
#import "LPSketch.h"
#import "LPLogging.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Declarations

extern NSSet *__LPSketchImport_returningIdsOfLayersToFlatten_discardFlattenedLayers_onMutable(NSMutableDictionary *layersByUID);
extern void __LPSketchImport_performActualAssetImport_onMutable(NSMutableDictionary *layersByUID,
                                                                NSSet *layersToFlatten,
                                                                void(^receivedAnImport_block)(NSDictionary *importedLayersByUID));


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Entrypoints

void LPSketchImport_attemptSketchImport(
    void(^__nonnull willFlattenLayersByUID_block)(NSDictionary *__nonnull layersByUID),
    BOOL(^__nonnull willImport_returningTrueIfShouldProceed_block)(NSString *__nonnull currentPageName),
    void(^__nonnull completeButDidntPerformImport_block)(NSString *_Nullable warningAlert_title_localizedString_orNilForNoAlert,
                                                         NSString *_Nullable warningAlert_message_localizedString_orNilForBlankMessage),
    void(^__nonnull receivedAnImport_block)(NSDictionary *_Nonnull importedLayersByUID)
)
{
    if (LPSketch_isSketchInstalled() == NO) {
        completeButDidntPerformImport_block(NSLocalizedString(@"Please install Sketch", nil),
                                            NSLocalizedString(@"Unable to perform the import because Sketch was not found.", nil));
        return;
    }
    if (LPSketch_isSketchRunning() == NO) {
        completeButDidntPerformImport_block(NSLocalizedString(@"Open your document in Sketch to import", nil),
                                            NSLocalizedString(@"It looks like Sketch is not currently running. To do an import, ensure your source document is open.", nil));
        return;
    }
    LPSketch_document(^(int terminationStatusCode,
                        NSString *stdoutString, NSString *stderrString,
                        NSString *scriptStringOutputFromStdOut_orNil,
                        NSMutableDictionary *scriptJSONOutputFromStdOut_orNil,
                        BOOL contextExists,
                        BOOL documentExists,
                        BOOL isSaved,
                        BOOL currentPageExists,
                        NSString *currentPageName,
                        BOOL numberOfArtboards,
                        BOOL hasArtboards)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            {
                if (contextExists == NO) {
                    completeButDidntPerformImport_block(NSLocalizedString(@"Sketch plugin context missing.", nil),
                                                        NSLocalizedString(@"An error occurred while importing from Sketch. Please ensure that your source document is open and ready to be imported.", nil));
                    return;
                }
                if (documentExists == NO) {
                    completeButDidntPerformImport_block(NSLocalizedString(@"No document open in Sketch", nil),
                                                        NSLocalizedString(@"In order to import from Sketch, ensure your source document is open.", nil));
                    return;
                }
                if (isSaved == NO) {
                    completeButDidntPerformImport_block(NSLocalizedString(@"Sketch document must be saved before import", nil),
                                                        NSLocalizedString(@"In order to import from Sketch, ensure your source document has been saved.", nil));
                    return;
                }
                if (currentPageExists == NO) {
                    completeButDidntPerformImport_block(NSLocalizedString(@"No pages found in Sketch document", nil),
                                                        nil);
                    return;
                }
                if (!currentPageName) {
                    completeButDidntPerformImport_block(NSLocalizedString(@"Current page name found", nil),
                                                        NSLocalizedString(@"An error occurred while importing from Sketch. The current page's name was not able to be obtained.", nil));
                    return;
                }
            }
            if (willImport_returningTrueIfShouldProceed_block == nil) {
                DDLogError(@"You must provide a willImport_returningTrueIfShouldProceed_block to SketchImport.");
                
                return;
            }
            BOOL shouldProceed = willImport_returningTrueIfShouldProceed_block(currentPageName);
            if (shouldProceed == NO) {
                // cancelled
                completeButDidntPerformImport_block(nil, nil);
                //
                return; // nothing to do
            }
            if (LPSketch_isSketchRunning() == NO) { // ensure Sketch still running…
                completeButDidntPerformImport_block(NSLocalizedString(@"Sketch was closed", nil),
                                                    NSLocalizedString(@"Unable to perform the import because Sketch was closed.", nil));
                return;
            }
            
            LPSketch_views(^(int terminationStatusCode,
                             NSString *stdoutString, NSString *stderrString,
                             NSString *scriptStringOutputFromStdOut_orNil,
                             NSMutableDictionary *scriptJSONOutputFromStdOut_orNil)
            {
                if (scriptJSONOutputFromStdOut_orNil.count > 0) {
                    NSMutableDictionary *layersByUID = scriptJSONOutputFromStdOut_orNil[@"layersByUID"]; // that's what we're expecting this to be, anyway....
                    if (layersByUID.count == 0) {
                        completeButDidntPerformImport_block(NSLocalizedString(@"No elements found to import", nil),
                                                            NSLocalizedString(@"There were no artboards, groups, or layers able to be found for import.", nil));
                        
                        return;
                    }
                    if (willFlattenLayersByUID_block) {
                        willFlattenLayersByUID_block(layersByUID);
                    }
                    
                    NSSet *layersToFlatten = __LPSketchImport_returningIdsOfLayersToFlatten_discardFlattenedLayers_onMutable(layersByUID);
                    
                    __LPSketchImport_performActualAssetImport_onMutable(layersByUID,
                                                                        layersToFlatten,
                                                                        receivedAnImport_block); // now we pass control to another fn… responsible for calling the receivedAnImport_block
                } else {
                    completeButDidntPerformImport_block(NSLocalizedString(@"Error while importing", nil),
                                                        NSLocalizedString(@"An unrecognized error occurred while trying to get layer information for the import.", nil));
                    
                    return;
                }
            });
        });
    });
}

void ___LPSketchImport_deleteDescriptionsOfLayersThatWillBeConsumedByFlatteningLayerId(NSString *layerId, NSMutableDictionary *layersByUID)
{
    NSMutableDictionary *layerDescriptionOfFlattenedLayer = layersByUID[layerId];
    NSArray *sublayerIds = layerDescriptionOfFlattenedLayer[@"sublayerIds"];
    for (NSString *sublayerId in sublayerIds) {
        ___LPSketchImport_deleteDescriptionsOfLayersThatWillBeConsumedByFlatteningLayerId(sublayerId, layersByUID); // do this /before/ deleting the sublayer description… :)
        [layersByUID removeObjectForKey:sublayerId];
    }
    { // finally,
        layerDescriptionOfFlattenedLayer[@"sublayerIds"] = @[]; // empty it
    }
}

NSSet *__LPSketchImport_returningIdsOfLayersToFlatten_discardFlattenedLayers_onMutable(NSMutableDictionary *layersByUID)
{
    NSMutableSet *allPossible_idsOfLayersToFlattenIntoAnImageView = [NSMutableSet new];
    { // Gather hierarchy shape data based on what will be flattened
        for (NSString *layerId in layersByUID) {
            NSMutableDictionary *layerDescription = layersByUID[layerId];
            NSString *sourceLayerClassName = layerDescription[@"sourceLayerClassName"];
            BOOL isLayerExportable = [layerDescription[@"isLayerExportable"] boolValue];
            BOOL isLayerKindOfMSShapePathLayer = [layerDescription[@"isLayerKindOfMSShapePathLayer"] boolValue];
            BOOL isLayerKindOfImmutableShapePathLayer = [layerDescription[@"isLayerKindOfImmutableShapePathLayer"] boolValue];
            BOOL shouldFlatten = NO;
            {
                if (isLayerExportable) {
                    shouldFlatten = YES;
                } else if (isLayerKindOfImmutableShapePathLayer) {
                    shouldFlatten = YES;
                } else if (isLayerKindOfMSShapePathLayer) {
                    shouldFlatten = YES;
                } else {
                    if ([sourceLayerClassName isEqualToString:@"MSBitmapLayer"]) {
                        shouldFlatten = YES;
                    } else if ([sourceLayerClassName isEqualToString:@"MSShapeGroup"]) {
                        shouldFlatten = YES;
                    } else if ([sourceLayerClassName isEqualToString:@"MSSliceLayer"]) {
                        shouldFlatten = YES;
                    }
                }
            }
            layerDescription[@"didFlatten"] = @(shouldFlatten);
            if (shouldFlatten) {
                [allPossible_idsOfLayersToFlattenIntoAnImageView addObject:layerId];
            }
        }
        { // And now that we're not going to get a mutation issue, let's clean up layers consumed by a flatten
            // NOTE: if a layerId contains other layer ids that are flattenable, we should
            for (NSString *layerId in allPossible_idsOfLayersToFlattenIntoAnImageView) {
                ___LPSketchImport_deleteDescriptionsOfLayersThatWillBeConsumedByFlatteningLayerId(layerId,
                                                                                                  layersByUID); // since we don't want to create Views for them via our import
            }
        }
    }
    NSMutableSet *afterCleanup_idsOfLayersToFlattenIntoAnImageView = [NSMutableSet new];
    {
        for (NSString *layerIdLeft in layersByUID) { // because now layersByUID has been cleaned up………
            NSMutableDictionary *layerDescription = layersByUID[layerIdLeft];
            BOOL didFlatten = [layerDescription[@"didFlatten"] boolValue];
            if (didFlatten) {
                [afterCleanup_idsOfLayersToFlattenIntoAnImageView addObject:layerIdLeft];
            }
        }
    }
    
    return afterCleanup_idsOfLayersToFlattenIntoAnImageView;
}

void __LPSketchImport_performActualAssetImport_onMutable(NSMutableDictionary *layersByUID,
                                                         NSSet *layersToFlatten,
                                                         void(^receivedAnImport_block)(NSDictionary *importedLayersByUID))
{
    DDLogInfo(@"Do layer flatten with %lu layersToFlatten", (unsigned long)layersToFlatten.count);
    NSArray *layerIds = [layersToFlatten allObjects];
    LPSketch_views_new_exportedImageDescriptionsByLayerIds_withLayerIds(layerIds,
                                                                        ^(int terminationStatusCode,
                                                                            NSString *stdoutString,
                                                                            NSString *stderrString,
                                                                            NSString *scriptStringOutputFromStdOut_orNil,
                                                                            NSMutableDictionary *scriptJSONOutputFromStdOut_orNil)
    {
        
        NSDictionary *layerExportDescriptionsByLayerId = scriptJSONOutputFromStdOut_orNil[@"layerExportDescriptionsByLayerId"];
        for (NSString *layerId in layerExportDescriptionsByLayerId) {
            NSDictionary *layerExportDescription = layerExportDescriptionsByLayerId[layerId];
            ((NSMutableDictionary *)layersByUID[layerId])[@"layerExportDescription"] = layerExportDescription;
        }
        
//        DDLogInfo(@"got these for the input……… %@", scriptJSONOutputFromStdOut_orNil);
        dispatch_async(dispatch_get_main_queue(), ^
        { // let's get us back into application-land……
            if (receivedAnImport_block) {
                receivedAnImport_block(layersByUID); // after this has been modified with the asset descriptions for the exported images………
            }
        });
    });
}