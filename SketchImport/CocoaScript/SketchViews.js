

////////////////////////////////////////////////////////////////////////////////
// Shared

function sketchVersionNumber()
{ // thanks to https://github.com/einancunlu/Flatten-Plugin-for-Sketch
    const version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
    var versionNumber = version.stringByReplacingOccurrencesOfString_withString(".", "") + ""
    while(versionNumber.length != 3) {
        versionNumber += "0"
    }
    //
    return parseInt(versionNumber)
}

////////////////////////////////////////////////////////////////////////////////

var state = {};
function sync_stateUpdatingOperation()
{
    var document = context.document; // we're assuming the doc has already been verified to exist by the time this is used
    var currentPage = [document currentPage];
    //
    var artboards = [currentPage artboards];
    state.document_hasArtboards = artboards.count() > 0;
    //
    var sourceLayersList;
    if (state.document_hasArtboards == true) {
        sourceLayersList = artboards
    } else {
        sourceLayersList = [currentPage layers]
    }
    var numberOfTopLevelLayers = [sourceLayersList count];
    var layerDescriptionsByUID = {};
    var truesByTopLevelUIDs = {};
    var sourceLayersLeftToProcess = [[NSMutableArray alloc] init];
//    log("numberOfTopLevelLayers " + numberOfTopLevelLayers);
    for (var i = 0 ; i < numberOfTopLevelLayers ; i++) { // first, not only to queue up the initial fodder for the following 'while' engine,
        // but to record which is a 'top level' view
        var topLevelLayer = [sourceLayersList objectAtIndex:i];
        var layerId = topLevelLayer.objectID();
        truesByTopLevelUIDs[layerId] = true; // we're just tracking what is a top level view
        [sourceLayersLeftToProcess addObject:topLevelLayer];
    }
    while ([sourceLayersLeftToProcess count] > 0) {
        var sourceLayer = sourceLayersLeftToProcess[0];
        [sourceLayersLeftToProcess removeObjectAtIndex:0]; // walk the head pointer down..
        
        var layerId = sourceLayer.objectID();
        var isTopLevel = truesByTopLevelUIDs[layerId] == true; // i.e. not null and not undefined and def not false
        var sourceLayerName = sourceLayer.name();

//        log("source layer sourceLayerName" + sourceLayerName + " isTopLevel " + isTopLevel);
        var isASymbol = typeof sourceLayer.sharedObjectID == "function" && sourceLayer.sharedObjectID() != null;
        
        
        var description = {};
        layerDescriptionsByUID[layerId] = description;
        
        description.layerId = layerId;
        description.name = sourceLayerName;
        
        if ([sourceLayer isKindOfClass:[MSShapePathLayer class]]) {
            description.isLayerKindOfMSShapePathLayer = true;
        } else {
            description.isLayerKindOfMSShapePathLayer = false;
        }
        if ([sourceLayer isKindOfClass:[MSImmutableShapePathLayer class]]) {
            description.isLayerKindOfImmutableShapePathLayer = true;
        } else {
            description.isLayerKindOfImmutableShapePathLayer = false;
        }
        
        description.sourceLayerClassName = sourceLayer.className();
        if (isTopLevel) {
            description.isTopLevel = true;
        } else {
            description.isTopLevel = false;
        }
//        description.isLayerExportable = sourceLayer.isLayerExportable();
        if ([sourceLayer isLayerExportable]) {
            description.isLayerExportable = true;
        } else {
            description.isLayerExportable = false;
        }
//        var current_artboard = [view parentArtboard]
        
        
        
        var layerFrame = [sourceLayer frame]; // MSRect
        description.layerFrame_X = [layerFrame x];
        description.layerFrame_Y = [layerFrame y];
        description.layerFrame_W = [layerFrame width];
        description.layerFrame_H = [layerFrame height];
        
        var absoluteRect = [sourceLayer absoluteRect]; // MSAbsoluteRect
        description.absoluteRect_X = [absoluteRect x];
        description.absoluteRect_Y = [absoluteRect y];
        description.absoluteRect_W = [absoluteRect width];
        description.absoluteRect_H = [absoluteRect height];
        description.absoluteRect_rulerX = [absoluteRect rulerX];
        description.absoluteRect_rulerY = [absoluteRect rulerY];

        var absoluteInfluenceRect = [sourceLayer absoluteInfluenceRect]; // CGRect
        description.absoluteInfluenceRect_X = absoluteInfluenceRect.origin.x;
        description.absoluteInfluenceRect_Y = absoluteInfluenceRect.origin.y;
        description.absoluteInfluenceRect_W = absoluteInfluenceRect.size.width;
        description.absoluteInfluenceRect_H = absoluteInfluenceRect.size.height;

        var slice;
        if (sketchVersionNumber() >= 350) {
            slice = [[MSExportRequest exportRequestsFromExportableLayer:sourceLayer inRect:absoluteInfluenceRect useIDForName:false] firstObject];
        } else { // legacy support
            slice = [[MSSliceMaker slicesFromExportableLayer:sourceLayer inRect:absoluteInfluenceRect] firstObject]
        }
        
        var sliceRect = [slice rect]; // MSRect
    
        description.sliceRect_X = sliceRect.origin.x;
        description.sliceRect_Y = sliceRect.origin.y;
        description.sliceRect_W = sliceRect.size.width;
        description.sliceRect_H = sliceRect.size.height;
        
        description.isASymbol = isASymbol;
// deprecated with old sketch versions
//        if (isASymbol) {
//            var sharedObjectID = sourceLayer.sharedObjectID();
//            description.sharedObjectID = sharedObjectID;
//        }
        
        if (typeof(sourceLayer.layers) == "function") { // apparently sometimes this might be missing??
            description.sublayerIds = [];
            var sublayers = sourceLayer.layers()
            var numberOfSublayers = [sublayers count];
            for (var sublayerIdx = 0 ; sublayerIdx < numberOfSublayers ; sublayerIdx++) {
                var sublayer = [sublayers objectAtIndex:sublayerIdx]
                [sourceLayersLeftToProcess addObject:sublayer]; // adding to the end -- after all the top level views
                // ^ note: we use '-addObject:' here because it's an NSMutableArray, not a JS Array
                
                // we also want to record the sublayerId for this view description
                var sublayerId = sublayer.objectID();
                description.sublayerIds.push(sublayerId);
            }
        } else {
//            log("no layers function here")
        }
        
        
        if ([sourceLayer isKindOfClass:[MSTextLayer class]]) {
            description.fontSize = [sourceLayer fontSize];
            description.fontPostscriptName = [sourceLayer fontPostscriptName];
            description.textColor_hexValue = [[sourceLayer textColor] hexValue];
            description.textAlignment = [sourceLayer textAlignment];
            
            description.stringValue = [sourceLayer stringValue];
        }
    }

    state.layersByUID = layerDescriptionsByUID;
    
}
sync_stateUpdatingOperation();


////////////////////////////////////////////////////////////////////////////////

function yieldProgramState()
{
//    log(state);
    var jsonData = [NSJSONSerialization dataWithJSONObject:state options:0 error:nil];
    if (jsonData) {
        var jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        log(jsonString);
    } else {
        log({"error" : "Nil JSON data from state."});
    }
}
yieldProgramState();